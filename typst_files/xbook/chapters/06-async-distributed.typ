#import "../style.typ": *

== 服务化推荐的分布式最小模型

这一节不是把异步编程当成主角，而是解释为什么这个项目不能只按“本地函数调用”来读。推荐请求会依赖用户行为服务、社交图、帖子元数据服务、模型服务、Kafka、Redis、可见性服务等外部系统。所谓线上推荐系统，不只是模型公式，而是一张服务依赖图。

=== 一次外部调用背后的五件事

看到下面这行，不要只把它翻译成语法上的“等待”：

```rust
let response = client.get_in_network_posts(request).await?;
```

它背后至少有五个工程问题：

- 请求发给谁？是本进程、同机服务、同机房服务，还是跨机房服务？
- 最坏要等多久？有没有超时、重试、fallback？
- 失败时当前请求应该失败，还是跳过这个结果继续？
- 返回的数据是否可信？是否可能为空、过期、部分缺失？
- 这个等待是否阻塞其他独立工作？

推荐系统的复杂度就在这里。一个用户刷新 feed，服务端可能同时访问几十个外部依赖。它们每个都可能慢、空、失败、返回旧数据。新手入门时不要急着背 RPC 框架名，先把这五个问题问清楚。

=== 串行等待和并行等待

先看串行等待：

```rust
let a = call_a().await;
let b = call_b().await;
let c = call_c().await;
```

如果每个调用 50ms，总耗时接近 150ms。再看并行等待：

```rust
let futures = vec![call_a(), call_b(), call_c()];
let results = join_all(futures).await;
```

如果三个调用互不依赖，总耗时接近最慢的那个，例如 50ms 到 70ms。`candidate-pipeline` 在 query hydrator、source、candidate hydrator 中大量使用 `join_all`，就是为了把独立的外部等待并行化。

#tip("并行不是免费午餐", [
  并行会降低一次请求的等待时间，但会增加下游系统的瞬时压力。如果每个请求都同时打十几个服务，下游容量、限流、缓存命中率都会变成设计问题。
])

=== 依赖关系决定能否并行

能并行的典型例子：

- 获取关注列表和获取屏蔽列表通常都只依赖 user id。
- Thunder source 和 Phoenix source 都读取已补齐的 query，并各自返回候选。
- 多个候选 hydrator 都读取同一批 candidates，并各自补不同字段。

不能随便并行的典型例子：

- dependent query hydrator 必须等第一批 query hydrator 完成。
- filter 必须顺序缩小候选集合。
- scorer 可能依赖前一个 scorer 写入的字段，例如先写 Phoenix 预测，再计算最终分。

判断标准很朴素：后一步是否需要前一步的输出。如果需要，就顺序；如果只读同一份输入并写不同字段，才可能并行。

=== 失败不是异常情况，而是常态

`Source::run` 的默认实现会把错误记录下来，然后返回 `Err`。但 `CandidatePipeline::fetch_candidates` 收集结果时用了：

```rust
for mut candidates in results.into_iter().flatten() {
    collected.append(&mut candidates);
}
```

这意味着失败的 source 不会贡献候选，但成功的 source 仍然能继续。这个设计体现了推荐系统常见的降级思路：某个召回源挂了，不一定让整个 feed 挂掉。

hydrator 的设计也类似。某个候选的某个字段补不出来，可能只是这个字段保持默认值，后续由 filter 判断是否移除。这样可以避免一个候选或一个字段拖垮整批请求。

#caution("降级要被观测", [
  降级不是忽略错误。系统可以继续返回结果，但必须记录错误率、空结果率、缓存命中率、过滤率和延迟。否则线上质量下降时很难定位。
])

=== 后台任务和当前响应

`run_side_effects` 使用 `tokio::spawn`：

```rust
tokio::spawn(async move {
    let futures = side_effects.iter().map(|se| se.run(input.clone()));
    let _ = join_all(futures).await;
});
```

这说明 side effect 不阻塞当前返回。用户不必等曝光日志写完、Kafka 发送完、缓存更新完才看到 feed。但这也带来另一个问题：后台失败不会自然反馈给当前请求，所以必须靠指标和日志发现。

这类代码体现的是服务化系统的边界划分。你会看到系统把工作分成两类：

- 必须完成才能返回：例如核心候选、必要过滤、排序。
- 可以返回后继续：例如日志、统计、某些缓存写入。

=== 延迟预算

线上推荐有一个隐含约束：用户等待时间有限。假设一次请求目标是 300ms，不能把它平均分给所有阶段，因为最慢的尾部请求会拖垮体验。一个简单预算可以写成：

#table(
  columns: (1.4fr, 1fr, 3fr),
  inset: 6pt,
  stroke: 0.5pt + line,
  [阶段], [预算], [主要风险],
  [Query hydration], [40ms], [社交图、用户行为服务慢或超时。],
  [Sources], [80ms], [某个召回源慢，导致候选不足或整体等待。],
  [Candidate hydration], [70ms], [批量元数据服务慢、缓存命中低。],
  [Scoring], [80ms], [模型服务延迟、候选过多。],
  [Selection + post filters], [20ms], [规则过多、排序数据结构低效。],
  [余量], [10ms], [序列化、调度、线程切换、网络抖动。],
)

真实系统不会这么简单，但新手可以先用这种表理解“为什么召回不能无限多、为什么 hydration 要缓存、为什么 side effect 要后台化”。这些知识都是为了读懂项目的服务边界和成本结构。

=== 本节练习

1. 在 `candidate-pipeline/candidate_pipeline.rs` 里找出 source、hydrator、scorer 和 side effect 访问外部系统的位置，区分单个调用和 fan-out 调用。
2. 任选一个 source，写下它失败时当前 pipeline 会发生什么。
3. 任选一个 side effect，解释它为什么不应该阻塞当前响应，以及它失败后应该通过什么指标被发现。
