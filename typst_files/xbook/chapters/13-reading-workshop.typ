#import "../style.typ": *

== 端到端读码工作坊

前面的章节按组件类型拆开讲。这一节反过来：给出几个真实排查场景，练习如何把 query、source、hydrator、filter、scorer、selector 和 side effect 连起来。

=== 场景一：用户打开 For You，系统返回空

排查空结果时，不要先猜模型坏了。按数据流向下走：

1. 请求是否进入正确的 server 方法？
2. query hydrator 是否成功补齐用户行为、关注列表、屏蔽列表？
3. source 是否启用？每个 source 返回多少候选？
4. candidate hydrator 是否大量失败？
5. 哪个 filter 移除了最多候选？
6. PhoenixScorer 是否返回预测？
7. selector 前是否已经没有候选？
8. post-selection filter 是否把候选全部移除？

把这八步写成一张表，空结果问题通常会很快缩小范围。

#table(
  columns: (1.2fr, 2.2fr, 2.6fr),
  inset: 6pt,
  stroke: 0.5pt + line,
  [位置], [看什么], [可能结论],
  [Query hydration], [scoring/retrieval sequence 是否存在], [用户行为服务失败或新用户冷启动。],
  [Sources], [candidate_count], [召回源未启用、下游失败、参数过小。],
  [Hydration], [missing/error count], [元数据服务失败，候选无法通过后续 filter。],
  [Filters], [removed_per_filter], [可见性、年龄、重复、社交图规则移除过多。],
  [Scoring], [score 是否写入], [模型服务失败或默认分导致排序异常。],
  [Selection], [selected_count], [top K 前候选不足或混排规则丢弃。],
)

=== 场景二：feed 变慢

延迟问题要区分“一个慢调用”和“一组调用的尾延迟”。如果 source 并行运行，总耗时接近最慢 source；如果 filter 顺序运行，总耗时是多个 filter 的累加。

排查顺序：

- 看 `execute` 总延迟。
- 拆 query hydrators、sources、hydrators、scorers 的 stage latency。
- 在慢 stage 内按 component name 看 latency。
- 看输入 size 是否异常变大。
- 看缓存命中率是否下降。
- 看外部依赖错误率是否上升，重试是否放大延迟。

一个常见误判是：只看平均延迟。推荐系统更关心 P95/P99，因为用户体验常被尾部依赖拖慢。

=== 场景三：同一个作者出现太多

这个问题可能出现在多个层次：

- source 本身返回了大量同作者候选。
- filter 没有去掉会话或 retweet 重复。
- RankingScorer 的作者多样性参数太弱。
- Selector 或 BlenderSelector 插入规则改变了相对位置。

排查时先看候选进入 scorer 前的作者分布，再看 `apply_author_diversity` 后的分数变化，最后看 selector 输出序列。

=== 场景四：新用户推荐不好

新用户问题通常不是单个模型能解决的。你要检查：

- `retrieval_sequence` 和 `scoring_sequence` 是否足够长。
- `PhoenixRetrievalNewUserHistoryThreshold` 是否触发新用户 cluster。
- 是否启用了 topic retrieval 或 fallback source。
- 关注列表是否足够支持 ThunderSource。
- OON 权重是否对新用户有特殊处理。

这类场景适合画出决策树，而不是只看最终分数。

=== 场景五：曝光日志缺失

如果用户看到了内容，但日志缺失，问题通常在 side effect 链路：

- side effect 是否启用？检查 `enable` 条件。
- selected_candidates 是否为空？
- serialization 是否失败？
- Kafka client 是否发送失败？
- 后台任务是否有错误指标？

这类问题不会影响当前响应，但会影响训练数据、实验分析和审计。

=== 读码模板

以后读任何新组件，都用下面模板：

```text
组件名：
阶段：
输入：
输出：
是否 async：
等待的外部系统：
enable 条件：
失败策略：
写入字段：
下游依赖：
关键指标：
用户可见影响：
```

这个模板可以逼迫你把“看懂代码”变成“看懂系统行为”。

=== 本节练习

1. 用上面的模板分析 `PhoenixSource`。
2. 用上面的模板分析 `CoreDataCandidateHydrator`。
3. 用上面的模板分析 `RankingScorer`。
4. 写一个空结果排查 runbook，限制在 12 步以内。

