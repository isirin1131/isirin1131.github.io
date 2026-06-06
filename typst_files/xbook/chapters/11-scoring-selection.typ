#import "../style.typ": *

== Scoring 和 Selection，从预测到最终顺序

过滤之后，剩下的候选还没有最终顺序。Scoring 阶段负责写入排序信号，Selection 阶段负责选择和混排。

=== Scorer 的合约

#codepath("candidate-pipeline/scorer.rs") 和 hydrator 很像，也要求返回结果长度和输入一致：

```rust
async fn score(&self, query: &Q, candidates: &[C]) -> Vec<Result<C, String>>;
fn update(&self, candidate: &mut C, scored: C);
```

scorer 不删除候选。它只写字段，例如 Phoenix 预测、加权分、最终分。

pipeline 顺序运行 scorer：

```rust
for scorer in all.iter().filter(|s| s.enable(query)) {
    let scored = scorer.run(query, &candidates).await;
    scorer.update_all(&mut candidates, scored);
}
```

顺序运行的原因是 scorer 之间可能有依赖。`RankingScorer` 需要读取 `PhoenixScorer` 写入的 `phoenix_scores`。

=== PhoenixScorer：调用模型服务

#codepath("home-mixer/scorers/phoenix_scorer.rs") 做三件事：

1. 根据 query 选择 Phoenix cluster。
2. 把 query 和 candidates 构造成 prediction request。
3. 调用 prediction client，把返回的 per-candidate score 写回 candidate。

它还包含一些线上逻辑，例如新用户阈值、decider override、egress sidecar fallback。新手不必一次看懂所有参数，但要知道这些不是模型结构，而是线上流量治理和实验控制。

=== RankingScorer：把多行为预测变成分数

#codepath("home-mixer/scorers/ranking_scorer.rs") 把 Phoenix 的多行为预测加权：

```rust
let combined_score = favorite * favorite_weight
    + reply * reply_weight
    + retweet * retweet_weight
    + not_interested * not_interested_weight
    + block_author * block_author_weight
    + ...;
```

然后它会：

- normalize score。
- 做作者多样性调整。
- 对 out-of-network 候选乘以 OON 权重。
- 写入 `weighted_score` 和 `score`。

这一步体现了推荐系统的目标组合：模型预测行为概率，业务参数决定如何权衡这些行为。

#tip("分数是产品目标的编码", [
  分数不是自然存在的真理。它是多种目标的加权结果：喜欢、回复、停留、关注作者、负反馈、多样性、OON 探索等。调分就是调产品目标。
])

=== 作者多样性

`RankingScorer` 中的 `apply_author_diversity` 会按分数排序，然后对同一作者的第 2 条、第 3 条内容做衰减。它的目标是避免一个作者连续占据太多位置。

这类规则说明推荐系统不只是最大化每条内容的独立分数。最终 feed 是一个序列，序列体验会受到重复作者、重复话题、广告间隔、会话结构等影响。

=== Selector 的合约

#codepath("candidate-pipeline/selector.rs") 负责排序和截断：

```rust
fn score(&self, candidate: &C) -> f64;

fn sort(&self, candidates: Vec<C>) -> Vec<C> {
    sorted.sort_by(|a, b| self.score(b).partial_cmp(&self.score(a)).unwrap_or(...))
}
```

`TopKScoreSelector` 很简单：读取 `candidate.score`，选择前 K 个。

```rust
fn score(&self, candidate: &PostCandidate) -> f64 {
    candidate.score.unwrap_or(f64::NEG_INFINITY)
}
```

如果候选没有 score，它会排到最后。这也是一个默认值语义：没有分数不是 0 分，而是负无穷。

=== BlenderSelector：最终 feed 不是只有帖子

#codepath("home-mixer/selectors/blender_selector.rs") 是外层 For You pipeline 的 selector。它先把 FeedItem 分成 posts、ads、who-to-follow、prompts、push-to-home，然后：

- 用 ads blender 混入广告。
- 插入 prompts。
- 插入 who-to-follow。
- 把 push-to-home 固定到开头。

这说明最终 selector 不一定只是按分数排序。不同 item 类型会有固定位置、间隔规则和产品约束。

=== 本节练习

1. 打开 `RankingScorer`，找出正反馈、负反馈、多样性、OON 权重分别在哪段代码。
2. 修改一个假想候选的 favorite/reply/not_interested 分数，手算加权分变化。
3. 对比 `TopKScoreSelector` 和 `BlenderSelector`，说明它们为什么服务不同层级的 pipeline。

