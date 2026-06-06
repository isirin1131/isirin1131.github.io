#import "../style.typ": *

== 错误处理和降级策略

推荐系统的外部依赖很多，错误处理是主线能力。一个成熟系统不会因为任何一个下游失败就完全不可用，也不会静默吞掉所有错误。本节整理常见降级模式。

=== Source 失败：跳过一路候选

`fetch_candidates` 对 source 结果使用 `flatten` 收集成功值。失败 source 不贡献候选，其他 source 继续。

适用场景：

- 多路召回互相补充。
- 单个 source 不是唯一候选来源。
- 下游短暂失败时仍可返回 feed。

风险：

- 某路 source 长期失败，用户体验变差但请求不报错。
- 如果没有 per-source candidate_count 告警，问题可能被隐藏。

=== Hydrator 失败：保留默认字段

hydrator 对单个候选返回 Err 时，`update_all` 不更新该候选。后续 filter 决定是否移除。

适用场景：

- 某些字段非关键。
- 后续有完整性 filter。
- 允许部分候选缺字段。

风险：

- 默认值被误解释为真实值。
- 安全相关字段缺失却放行。

=== Scorer 失败：分数缺失或默认

PhoenixScorer 如果 prediction 请求失败，会给每个候选返回 Err；update 时不会写 phoenix_scores。RankingScorer 可能仍运行，但 score 质量会下降。

对核心 scorer，通常需要更强监控。因为请求可能仍有结果，但排序质量已经坏了。

=== Query hydrator 失败：上下文缺失

query hydrator 失败时，对应字段保持默认。这个模式最危险，因为默认值可能与真实空值混淆。

例如空关注列表可能是“没有关注”，也可能是“社交图失败”。如果后续没有错误标记，就难以区分。

=== Side effect 失败：当前成功，未来受损

side effect 在后台执行，失败不影响当前响应。但它会影响：

- served history 去重。
- 缓存复用。
- 训练数据。
- 实验分析。
- 审计和问题排查。

side effect 必须有错误率指标和必要的重试或补偿机制。

=== 降级决策表

#table(
  columns: (1.3fr, 1.5fr, 2.6fr),
  inset: 5pt,
  stroke: 0.5pt + line,
  [失败点], [当前请求], [后续风险],
  [单个 source], [可继续], [候选结构变化。],
  [核心 query hydrator], [可继续], [上下文缺失，个性化下降。],
  [core data hydrator], [可继续到 filter], [候选可能被完整性过滤。],
  [PhoenixScorer], [可能继续], [排序质量下降。],
  [VFFilter 数据], [风险高], [安全放行或误杀。],
  [served history side effect], [当前成功], [重复展示。],
  [Kafka 日志 side effect], [当前成功], [训练和分析缺失。],
)

=== 本节练习

1. 找一个 source，写出它失败后的 pipeline 行为。
2. 找一个 query hydrator，分析默认值是否安全。
3. 设计一个 side effect 失败告警，说明为什么不能只看当前请求成功率。

