#import "../style.typ": *

== 观测性 Dashboard，怎样知道系统正在变坏

推荐系统依赖太多组件，不可能靠用户反馈才发现问题。你需要 dashboard 把候选流动、延迟、过滤、打分、缓存、side effect 全部串起来。

=== Dashboard 的核心思想

每个阶段都要记录三类信息：

- 量：输入多少、输出多少。
- 时：花了多久。
- 质：错误率、缺失率、过滤率、分数分布。

只看延迟不够，只看最终结果数也不够。推荐系统的问题经常是“结果还在，但质量已经变差”。

=== 顶层面板

顶层面板应该回答：系统整体是否健康？

#table(
  columns: (1.8fr, 2.8fr),
  inset: 5pt,
  stroke: 0.5pt + line,
  [指标], [意义],
  [request count], [流量是否异常。],
  [execute latency P50/P95/P99], [用户等待是否变慢。],
  [final result size], [是否空结果或供给不足。],
  [error rate], [整体错误趋势。],
  [in-network/OON ratio], [候选结构是否变化。],
  [negative feedback rate], [用户不满是否上升。],
)

=== Stage 面板

每个 stage 都应该有 latency 和 size：

- query hydrators latency。
- source candidate_count。
- hydrator missing/error count。
- filter kept/removed/filter_rate。
- scorer latency 和 score missing。
- selector selected_count。
- side effect error count。

这些指标能告诉你候选在哪一段变少，延迟在哪一段变高。

=== Component 面板

stage 只告诉你哪一层有问题，component 面板告诉你具体是谁：

```text
query_hydrator.name -> latency/error
source.name -> candidate_count/error
hydrator.name -> latency/missing/cache_hit
filter.name -> removed_count/filter_rate
scorer.name -> latency/error
side_effect.name -> error/latency
```

`candidate-pipeline` 中的 tracing span 已经记录了许多 component name，这是构建 dashboard 的基础。

=== 分布面板

推荐系统不能只看总量，还要看分布：

- 每个 source 的候选占比。
- 每个 served_type 的最终占比。
- 每个 author 的重复度。
- score 分布。
- action probability 分布。
- filter reason 分布。
- visibility reason 分布。

分布变化往往比均值更早暴露问题。

=== 告警设计

告警不要太多，但要覆盖核心失败：

- final result size 接近 0。
- execute P99 超阈值。
- 某个核心 source candidate_count 急剧下降。
- CoreData missing 激增。
- VFFilter 移除率异常。
- PhoenixScorer 错误率升高。
- served candidates Kafka side effect 失败。
- cache hit rate 突降。

告警要能指向阶段，否则值班同学只能看到“feed 坏了”，不知道从哪里查。

=== 调试截图模板

事故排查时，建议固定截取：

```text
1. 总请求量和总延迟
2. final result size
3. source candidate_count by source
4. filter removed_count by filter
5. hydrator missing/error by hydrator
6. scorer latency/error
7. side effect failures
8. 最近参数和发布变化
```

这组截图能支持多数复盘。

=== 本节练习

1. 为 `CandidatePipeline::execute` 画一个 dashboard 草图。
2. 设计一个空结果告警，要求能区分 source 供给不足和 filter 误杀。
3. 设计一个缓存异常告警，包含 hit rate、Redis latency、cached path result size。

