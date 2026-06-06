#import "../style.typ": *

== 练习工作簿

这一节集中给出可执行练习。建议读者每学完一组章节，就做对应练习。目标不是背答案，而是训练“从代码证据推导系统行为”的能力。

=== 练习 1：画出端到端流程

输入：用户打开 For You。  
要求：画出从 gRPC request 到 final FeedItem 的流程图。

必须包含：

- QueryBuilder
- ScoredPostsServer
- PhoenixCandidatePipeline
- ForYouCandidatePipeline
- side effects

检查标准：能说清楚哪一层返回 PostCandidate，哪一层返回 FeedItem。

=== 练习 2：追踪 `has_cached_posts`

用搜索工具找到 `has_cached_posts` 的所有读写位置。写出：

- 谁写它。
- 谁读它。
- true 时哪些 source 跳过。
- true 时哪些 side effect 跳过。
- 它如何改变延迟和新鲜度。

=== 练习 3：模拟 filter pipeline

构造 10 个候选：

- 2 个重复 tweet id。
- 1 个 author_id=0。
- 2 个 blocked author。
- 1 个 visibility drop。

手动计算每个 filter 后剩余多少候选。

=== 练习 4：手算分数

给三个候选：

```text
A fav=0.2 reply=0.01 dwell=0.3 not_interested=0.01
B fav=0.1 reply=0.08 dwell=0.5 not_interested=0.02
C fav=0.05 reply=0.02 dwell=0.2 not_interested=0.10
```

自定义权重，计算排序。然后把 not_interested 权重加大，观察变化。

=== 练习 5：设计 source

设计一个新 source。写出：

- enable 条件。
- query 输入。
- 外部依赖。
- 返回候选字段。
- 失败策略。
- 指标。

不要写代码也可以，但设计必须能放进 `CandidatePipeline`。

=== 练习 6：写一份空结果 Runbook

限制 12 步以内。必须覆盖：

- query hydration
- source candidate count
- hydration missing
- filter removed count
- scorer score missing
- selector selected count

=== 练习 7：审查安全默认值

找三个安全或可见性相关字段，分析 None/false/empty 的语义。判断默认值是否安全，并写出需要的监控。

=== 练习 8：读一个 side effect

选择一个 side effect，回答：

- enable 条件。
- 输入 selected 还是 non_selected。
- 写哪个外部系统。
- 当前失败是否影响响应。
- 后续失败影响什么闭环。

=== 练习 9：本地 Phoenix demo

阅读 `phoenix/run_pipeline.py`，解释：

- artifacts 目录有哪些文件。
- retrieval 如何得到 top K。
- ranking 如何得到 action probability。
- 本地 weighted score 和线上 RankingScorer 有什么区别。

=== 练习 10：写复盘

假设 `PhoenixSource` 因 retrieval_sequence 缺失导致 OON 候选下降。写一份复盘：

- 影响范围。
- 根因。
- 为什么监控没发现。
- 修复。
- 长期防护。

