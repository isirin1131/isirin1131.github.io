#import "../style.typ": *

== Selector 和混排，feed 是一个序列

Selector 不只是“取 top K”。在帖子候选流水线里，selector 可以很简单；在最终 feed 流水线里，selector 要处理广告、关注推荐、提示和置顶内容。本节对比 `TopKScoreSelector` 和 `BlenderSelector`。

=== TopKScoreSelector：帖子候选层

#codepath("home-mixer/selectors/top_k_score_selector.rs") 很短：

```rust
fn score(&self, candidate: &PostCandidate) -> f64 {
    candidate.score.unwrap_or(f64::NEG_INFINITY)
}

fn size(&self) -> Option<usize> {
    Some(params::TOP_K_CANDIDATES_TO_SELECT)
}
```

它依赖 `RankingScorer` 已经写入 `candidate.score`。如果 score 缺失，使用负无穷，避免未打分候选排到前面。

这是内层帖子推荐的典型 selector：排序、截断、把剩下的放到 non_selected。

=== BlenderSelector：最终 feed 层

#codepath("home-mixer/selectors/blender_selector.rs") 处理的是 `FeedItem`，不只是帖子。它先 partition：

```rust
let PartitionedFeedItems {
    posts,
    ads,
    wtf_modules,
    prompts,
    push_to_home,
} = partition_feed_items(candidates);
```

然后选择广告混排策略：

```rust
let blender: &dyn AdsBlender = match blender_type.as_str() {
    "safe_gap" => &self.safe_gap_blender,
    _ => &self.partition_organic_blender,
};
```

最后插入 prompts、who-to-follow、push-to-home。

=== 为什么最终 feed 不能只按分数排序

最终 feed 是多种 item 的组合。不同 item 有不同目标：

- 帖子：相关性、互动、内容质量。
- 广告：商业投放、间隔、安全。
- Who to follow：关系增长。
- Prompt：产品引导或运营目标。
- Push to home：特殊入口或强策略内容。

如果统一用一个 score 排序，会很难表达固定位置、间隔、曝光频控和产品优先级。

=== 混排的三个层次

混排可以分成三层：

#table(
  columns: (1.2fr, 3.4fr),
  inset: 5pt,
  stroke: 0.5pt + line,
  [层次], [说明],
  [候选内排序], [帖子之间按 relevance score 排序。],
  [异类 item 插入], [广告、关注推荐、提示按规则插入。],
  [最终约束修正], [安全间隔、置顶、去重、位置修正。],
)

`TopKScoreSelector` 主要处理第一层；`BlenderSelector` 处理第二、三层。

=== non_selected 的意义

Selector 返回 `SelectResult`：

```rust
pub struct SelectResult<C> {
    pub selected: Vec<C>,
    pub non_selected: Vec<C>,
}
```

non_selected 不是无用数据。它可以用于：

- side effect 记录哪些候选没展示。
- 缓存较高分但本次没展示的候选。
- 分析 selector 丢弃率。
- 训练时构造展示边界附近样本。

`BlenderSelector` 还会为被丢弃的 posts/ads 构造 placeholder，保留统计语义。

=== 广告混排的特殊性

广告不是普通帖子。它需要：

- 遵守插入间隔。
- 尊重 brand safety。
- 记录 impression id。
- 处理商业投放约束。
- 不破坏用户体验。

因此 ads 先作为 source 进入外层 pipeline，再由 BlenderSelector 控制位置。这比把广告直接塞进帖子排序模型更清晰。

=== Selector 排查模板

```text
selector:
input_count:
selected_count:
non_selected_count:
score field:
missing score count:
item type distribution before:
item type distribution after:
fixed position rules:
ads dropped:
posts dropped:
```

对最终 feed 问题，必须看 item type distribution。只看帖子分数不够。

=== 本节练习

1. 对比 `TopKScoreSelector` 和 `BlenderSelector` 的输入类型。
2. 解释为什么 `BlenderSelector::score` 返回 0 也没问题。
3. 设计一个规则：每 8 条 organic post 后最多 1 条广告。写出它属于混排的哪一层。
4. 思考：如果 push-to-home 插入开头，会不会影响其他 item 的 position 语义？

