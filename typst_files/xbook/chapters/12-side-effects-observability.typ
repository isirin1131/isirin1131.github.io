#import "../style.typ": *

== Side Effects 和观测性，返回之后系统还在工作

当 pipeline 选出最终候选后，请求并没有真正结束。系统还要写日志、更新缓存、记录 served history、发送 Kafka 事件、统计实验数据。这些操作通常不改变当前响应，但会影响后续推荐和问题排查。

=== SideEffect 的合约

#codepath("candidate-pipeline/side_effect.rs") 定义了 side effect 输入：

```rust
pub struct SideEffectInput<Q, C> {
    pub query: Arc<Q>,
    pub selected_candidates: Vec<C>,
    pub non_selected_candidates: Vec<C>,
}
```

它能看到：

- 当前 query。
- 最终选中的候选。
- 没有被选中的候选。

side effect 可以据此写曝光日志、缓存候选、统计被丢弃的数据，或者记录实验对照信息。

=== 为什么不阻塞响应

`CandidatePipeline::run_side_effects` 用 `tokio::spawn` 后台执行：

```rust
tokio::spawn(async move {
    let futures = side_effects
        .iter()
        .filter(|se| se.enable(input.query.clone()))
        .map(|se| se.run(input.clone()));
    let _ = join_all(futures).await;
});
```

这样做的动机是降低用户可见延迟。当前响应已经有最终候选，不应该等 Kafka 或 Redis 写入完成。

但后台执行也带来风险：如果 side effect 持续失败，当前请求可能看起来成功，长期数据却坏了。比如 served history 没写进去，用户可能重复看到同一批内容；曝光日志缺失，训练数据和实验分析会偏。

=== 例子：ServedCandidatesKafkaSideEffect

#codepath("home-mixer/side_effects/served_candidates_kafka_side_effect.rs") 会把 selected feed items 序列化成 thrift，然后发送到 Kafka。

它先根据 query 构造 request_info，再遍历 selected items：

```rust
for item in items {
    if let Some(entry_info) = build_entry_info(item) {
        let served = ServedEntry { request: request_info.clone(), entry: Some(Box::new(entry_info)) };
        let bytes = serialize_compact(&served)?;
        payloads.push(bytes);
    }
}
```

最后并行发送：

```rust
let futs: Vec<_> = payloads.iter().map(|bytes| self.kafka_client.send(bytes)).collect();
let results = futures::future::join_all(futs).await;
```

这是一条典型日志链路：把线上展示事实写出去，供后续分析、训练、审计或回放使用。

=== 观测性三件套

本项目里常见的观测方式包括：

- tracing span：记录阶段名、组件名、输入数量、输出数量、过滤率等。
- stats receiver：记录指标，例如 result size、cache hit/miss、filter kept/removed。
- structured log：记录错误、延迟、移除摘要等。

观测性不是上线后再补的装饰。推荐系统依赖太多，只有把每段输入输出都量化，才能知道问题发生在哪里。

=== 常见线上问题和对应指标

#table(
  columns: (1.7fr, 3.2fr),
  inset: 6pt,
  stroke: 0.5pt + line,
  [问题], [优先查看],
  [feed 空结果], [source candidate_count、filter removed_count、final result_size。],
  [延迟变高], [query hydrator/source/hydrator/scorer latency 分布。],
  [重复内容], [DropDuplicatesFilter removed、served history 写入、cached posts 逻辑。],
  [某类内容突然减少], [对应 source 返回量、topic filter、visibility filter、参数开关。],
  [训练数据异常], [served candidates Kafka side effect 错误率、曝光日志数量。],
)

=== Side effect 的可靠性设计

后台任务至少要考虑：

- 是否需要重试？
- 是否需要限流？
- 失败是否会积压内存？
- 是否需要 dead letter queue？
- 是否要把错误按组件名打点？
- 是否会泄露用户隐私或敏感字段？

这些问题超出了“推荐算法”的狭义范围，但它们决定系统能否长期稳定运行。

#checkpoint("推荐系统的闭环", [
  当前请求的 side effect 往往会成为未来请求的 query hydration 数据，也会成为未来训练样本的一部分。返回之后的写入，最终会影响下一轮推荐。
])

=== 本节练习

1. 在 `phoenix_candidate_pipeline.rs` 和 `for_you_candidate_pipeline.rs` 中列出 side effects，按缓存、日志、统计、实验分类。
2. 选一个 side effect，解释它失败对当前请求和后续请求分别有什么影响。
3. 设计一个 dashboard：至少包含 source 返回量、filter 过滤率、scorer 延迟、final result size、side effect 错误率。

