#import "../style.typ": *

== 参数调试手册

参数是线上推荐系统最常见的控制面。本节给出一份面向新手的调试手册：当你看到某个参数时，如何判断它影响什么、如何安全修改、如何验证。

=== 参数类型

常见参数可以分为：

#table(
  columns: (1.3fr, 3.2fr),
  inset: 5pt,
  stroke: 0.5pt + line,
  [类型], [例子],
  [数量], [source max results、top K、cache max posts。],
  [阈值], [新用户历史长度、最小视频时长、年龄阈值。],
  [权重], [favorite/reply/dwell/not interested/OON。],
  [开关], [是否启用 cached posts、是否启用某 source。],
  [策略名], [ads blender type、cluster id。],
  [超时], [Redis GET timeout、viewer data timeout。],
)

不同类型参数的风险不同。数量和超时影响成本与延迟；权重影响排序目标；开关和策略名可能改变整条路径。

=== 修改参数前的五个问题

1. 这个参数在哪些组件读取？
2. 它影响候选数量、过滤率、打分，还是混排？
3. 它是否只对某些用户或请求生效？
4. 有没有现成指标验证它生效？
5. 出问题时如何回滚？

如果回答不了，不应该直接调。

=== 权重参数

排序权重最敏感。调整 favorite、reply、dwell、negative feedback 会改变产品目标。建议：

- 一次只改少数权重。
- 先做小流量实验。
- 同时看正反馈和负反馈。
- 看分桶，不只看总体。
- 保留回滚配置。

负反馈权重尤其要小心。符号错误或绝对值过小都可能造成体验问题。

=== 数量参数

`PhoenixMaxResults`、`ThunderMaxResults`、top K 这类参数影响候选供给和成本。

调大：

- 可能提高召回覆盖。
- 会增加 hydration、filter、scoring 成本。
- 可能增加重复和低质候选。

调小：

- 降低成本和延迟。
- 增加候选不足风险。
- 在高过滤率请求上更危险。

数量参数要和过滤率、最终 result size 一起看。

=== 超时参数

超时不是越长越好。超时长能等到更多结果，但会拉高尾延迟；超时短能保护用户体验，但会增加降级率。

调超时时要看：

- 下游 P95/P99。
- 当前请求延迟预算。
- 降级后是否有可用 fallback。
- 超时错误是否可观测。

=== 开关参数

开关参数风险最大，因为它可能改变路径。例如 `EnableCachedPosts` 会使 cached path 接管，影响 source、hydrator、side effect 的 enable。

开关上线要明确：

- 默认关还是默认开。
- 哪些用户生效。
- 是否支持快速回滚。
- 关闭后是否有残留状态。

=== 参数变更记录模板

```text
参数名：
旧值：
新值：
影响组件：
影响用户范围：
预期变化：
观察指标：
上线时间：
回滚方式：
负责人：
```

这份记录看起来繁琐，但能避免事故后没人知道系统为什么变了。

=== 本节练习

1. 选择一个 source max results 参数，写出调大和调小的影响。
2. 选择一个 negative feedback 权重，设计实验指标。
3. 找一个 enable 开关，画出打开后 pipeline 路径变化。

