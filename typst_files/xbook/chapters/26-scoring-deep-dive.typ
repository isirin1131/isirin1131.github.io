#import "../style.typ": *

== Scorer 深度导读，从模型预测到最终分

Scorer 阶段最容易被新手误解成“模型调用”。实际线上 scorer 还包含 cluster 选择、fallback、权重组合、归一化、多样性和特殊人群逻辑。

=== PhoenixScorer 的职责边界

`PhoenixScorer` 做的是模型服务调用，不做最终加权排序。它的输出是 `phoenix_scores`，包含多种 action 的预测。

关键步骤：

1. 根据 query 解析 cluster。
2. 如果新用户历史少，切到新用户 cluster。
3. 根据 decider 做 override。
4. 构造 prediction request。
5. 选择 egress client 或普通 phoenix client。
6. 如果 egress 失败，fallback 到普通 client。
7. 把每个候选的预测写回 `PostCandidate`。

这个流程说明模型服务上线后也需要流量治理。cluster、sidecar、fallback 都是生产系统能力。

=== RankingScorer 的职责边界

`RankingScorer` 不调用 Phoenix 服务。它读取已有 `phoenix_scores`，计算最终排序分。

核心顺序是：

```text
Phoenix 多行为分数
  -> weighted score
  -> normalize
  -> author diversity
  -> OON weight
  -> final score
```

这些步骤都可能改变最终排序。排查排序问题时，要逐层看，而不是只看 Phoenix 原始预测。

=== 多行为权重

`ScoringWeights::from_params` 从参数系统读取权重。正反馈包括 favorite、reply、retweet、click、dwell、follow_author 等。负反馈包括 not_interested、block_author、mute_author、report、not_dwelled 等。

这让系统可以表达复杂目标：

- 提高 favorite 权重，会偏向轻互动内容。
- 提高 reply 权重，可能增加讨论性内容。
- 提高 dwell 权重，可能偏向长内容或视频。
- 加强负反馈权重，会更保守地避开用户讨厌的内容。

权重调节必须通过实验验证，因为行为之间会相互影响。

=== offset_score 的目的

`RankingScorer` 里有 `offset_score`。它处理 combined score 可能为负的情况，并把分数映射到适合后续排序的区间。

新手不必一开始记住公式，只需要理解：多行为加权不是简单加完就结束，还要处理负反馈、归一化和分数尺度。否则不同类型候选的分数不可比。

=== 作者多样性

`apply_author_diversity` 会先按 weighted score 排序，再按作者出现次数衰减分数。它有两个参数：

- decay factor：重复作者衰减速度。
- floor：最低保留比例。

这个设计避免同一作者刷屏，同时不至于把同一作者后续内容直接清零。

=== OON 权重

`effective_oon_weight` 会根据 topic request、新用户状态和默认参数选择 OON 权重。它说明最终分不仅与内容相关，还与候选来源有关。

OON 权重太低，用户会困在关注网络里；太高，用户可能看到过多陌生内容。这个权衡是 feed 产品的核心问题之一。

=== Scorer 排查模板

```text
候选 id:
served_type:
phoenix_scores 是否存在:
weighted_score:
normalized score:
author diversity multiplier:
oon multiplier:
final score:
selector rank:
```

用这个模板抽样 10 个候选，通常能快速定位排序异常发生在哪一步。

=== 本节练习

1. 手写一个候选的 favorite、reply、not_interested 加权分。
2. 给同一作者的三条候选模拟 diversity 衰减。
3. 比较 in-network 和 out-of-network 候选在 OON 权重后的分数变化。
4. 解释为什么 PhoenixScorer 和 RankingScorer 分成两个 scorer。

