#import "../style.typ": *

== 参数、开关和实验，线上系统怎样安全变化

真实推荐系统不能每次改一点策略都重新发布代码。很多行为由参数、feature switch、decider 和实验系统控制。本项目里你会反复看到 `query.params.get(...)` 和 `query.decider`。

=== 参数在哪里出现

在 source、hydrator、filter、scorer 中，参数控制很多行为：

- source 的最大结果数，例如 `PhoenixMaxResults`、`ThunderMaxResults`。
- 模型 cluster，例如 `PhoenixInferenceClusterId`。
- 新用户阈值，例如 `PhoenixRankerNewUserHistoryThreshold`。
- 排序权重，例如 favorite、reply、dwell、not interested。
- 多样性参数，例如 `AuthorDiversityDecay`、`AuthorDiversityFloor`。
- 过滤阈值，例如最大帖子年龄。
- 混排策略，例如 `AdsBlenderType`。

参数的价值是把可调策略从代码里抽出来。风险是参数组合变多，系统行为更难推断。

=== Decider override

`PhoenixScorer::resolve_cluster` 中有 decider override：

```rust
if let Some(decider) = &query.decider {
    match configured_cluster {
        PhoenixCluster::Experiment1Fou if decider.enabled("override_qf_use_lap7") => {
            return PhoenixCluster::Experiment1Lap7;
        }
        ...
    }
}
```

这说明即使参数配置了某个 cluster，decider 也可能按实验或开关把流量导到另一个 cluster。读线上代码时，不能只看默认参数，还要看实验开关和请求上下文。

=== 为什么需要实验

推荐系统目标复杂，很多改动无法只靠离线指标判断。例如提高 reply 权重可能增加互动，但也可能增加争议内容。上线前需要 A/B 实验观察：

- 用户停留和互动。
- 负反馈。
- 内容多样性。
- 新用户留存。
- 作者生态。
- 延迟和错误率。

实验不是证明代码能跑，而是判断产品目标是否真的变好。

=== 参数改动的风险

参数看起来比代码安全，但也可能造成严重影响：

- 把负反馈权重设错符号。
- 把 retrieval top K 调太大，导致 scoring 延迟上升。
- 把某个 source 关闭，导致候选不足。
- 把新用户阈值调错，导致大量用户走错模型 cluster。
- 把可见性相关开关关闭，造成安全风险。

因此重要参数需要审查、监控和回滚方案。

=== 阅读参数代码的步骤

看到 `query.params.get(X)`，按下面步骤追：

1. 这个参数在哪个阶段读取？
2. 它控制 enable、数量、阈值、权重，还是下游 cluster？
3. 默认值是什么？
4. 它是否和 decider 或 request type 共同作用？
5. 改它会影响延迟、召回量、过滤率，还是最终排序？
6. 有没有指标能验证它生效？

=== 实验分析的基本单位

一次推荐实验至少要同时看四类指标：

#table(
  columns: (1.3fr, 3.4fr),
  inset: 5pt,
  stroke: 0.5pt + line,
  [类别], [例子],
  [效果], [favorite、reply、dwell、retention、follow author。],
  [负反馈], [not interested、mute、block、report。],
  [供给], [source candidate count、filter rate、in-network/OON 占比。],
  [系统], [latency、error rate、cache hit、side effect failures。],
)

只看效果指标容易忽略系统成本；只看系统指标又无法判断用户体验是否变好。

=== 本节练习

1. 在 `home-mixer/scorers/ranking_scorer.rs` 中找出所有权重参数，按正反馈和负反馈分类。
2. 在 `PhoenixSource` 和 `PhoenixScorer` 中比较 new user threshold 的作用。
3. 设计一个实验：把 OON 权重提高 10%。写出你会观察的五个指标。

