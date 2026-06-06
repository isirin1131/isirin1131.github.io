#import "../style.typ": *

== Query Hydration，先把用户上下文补齐

推荐请求刚进入系统时，query 往往只有一部分信息：用户是谁、请求场景是什么、客户端带了哪些参数。它还不知道用户最近喜欢什么、关注谁、屏蔽谁、已经看过什么、是否有话题偏好。Query hydrator 的职责就是补齐这些上下文。

=== QueryHydrator 的合约

核心 trait 在 #codepath("candidate-pipeline/query_hydrator.rs")：

```rust
#[async_trait]
pub trait QueryHydrator<Q>: Any + Send + Sync
where
    Q: PipelineQuery,
{
    fn enable(&self, _query: &Q) -> bool { true }
    async fn hydrate(&self, query: &Q) -> Result<Q, String>;
    fn update(&self, query: &mut Q, hydrated: Q);
}
```

这个合约有两个动作：`hydrate` 负责去外部系统拿数据，返回一个只填了相关字段的新 query；`update` 负责把这些字段合并回主 query。

#beginner("为什么不直接修改原 query", [
  并行运行多个 query hydrator 时，如果大家同时写同一个对象，会出现竞争和合并问题。这个框架让 hydrator 先各自返回结果，再由 pipeline 顺序 merge，降低共享可变状态的复杂度。
])

=== 例子一：ScoringSequenceQueryHydrator

#codepath("home-mixer/query_hydrators/scoring_sequence_query_hydrator.rs") 会访问用户行为聚合服务。它根据 user id、窗口时间、最大序列长度、聚合类型、是否包含实时行为等参数，拿到 scoring sequence。

简化后：

```rust
let result = self
    .user_action_aggregation_client
    .fetch_aggregated_sequence(...)
    .await?;

Ok(ScoredPostsQuery {
    scoring_sequence: Some(result.sequence),
    columnar_scoring_sequence: result.columnar_bytes,
    ..Default::default()
})
```

这个调用访问的是用户行为服务。它不是模型调用，但它决定了模型能看到什么历史。如果这个序列缺失，Phoenix ranking 可能只能返回默认分或无法正常请求。

=== 例子二：FollowedUserIdsQueryHydrator

#codepath("home-mixer/query_hydrators/followed_user_ids_query_hydrator.rs") 更简单。它访问 social graph，拿当前用户关注的人：

```rust
let followed_user_ids = self
    .socialgraph_client
    .get_followed_user_ids(query.user_id)
    .await?;
```

这份数据至少影响两件事：

- ThunderSource 用它请求 in-network posts。
- 某些新用户逻辑会根据关注数判断用户状态。

这说明一个 query 字段可能服务多个后续阶段。读代码时不要只看 hydrator 自己，还要追踪这个字段被哪些 source、filter、scorer 使用。

=== 初始 hydrator 和 dependent hydrator

`CandidatePipeline::execute` 先跑 `hydrate_query`，再跑 `hydrate_dependent_query`。这给了框架一个表达依赖的方式。

如果某个 hydrator 只依赖原始 query，它应该放在第一批。例如关注列表、屏蔽列表、用户行为序列。  
如果某个 hydrator 依赖第一批补出来的字段，它应该放在 dependent 阶段。

这个划分比“全部顺序跑”更有效，也比“全部并行跑”更安全。

=== Query hydration 的失败策略

Query hydrator 失败后，pipeline 在 `hydrate_query` 中只会在 `Ok(hydrated)` 时调用 `update`：

```rust
for (hydrator, result) in hydrators.iter().zip(results) {
    if let Ok(hydrated) = result {
        hydrator.update(&mut hydrated_query, hydrated);
    }
}
```

这意味着失败字段会保持默认状态。默认状态是否安全，要看后续组件如何处理。

例如：

- scoring sequence 缺失时，PhoenixScorer 会返回默认 candidate。
- followed_user_ids 缺失时，ThunderSource 可能拿不到 in-network 候选。
- blocked_user_ids 缺失时，如果后续没有其他保护，可能影响用户安全体验。

#caution("默认值不是天然安全", [
  写 hydrator 时必须思考默认值的语义。空列表可能表示“用户没有关注任何人”，也可能表示“社交图服务失败”。这两种情况后续处理不一定相同。
])

=== 如何读一个 query hydrator

读任何 query hydrator，都按下面模板记笔记：

#table(
  columns: (1.4fr, 3.4fr),
  inset: 6pt,
  stroke: 0.5pt + line,
  [问题], [说明],
  [它补哪个字段？], [看 `Ok(ScoredPostsQuery { ... })` 和 `update`。],
  [它依赖哪个系统？], [看调用的 client、请求参数和错误处理。],
  [它如何选择参数？], [看 `query.params.get(...)` 和 `query.decider`。],
  [失败后默认值是什么？], [看 pipeline 合并逻辑和下游组件。],
  [谁会使用这个字段？], [用 `rg` 搜字段名。],
)

=== 本节练习

1. 在 `phoenix_candidate_pipeline.rs` 中列出所有 query hydrator，并给每个标注它大概补什么字段。
2. 用 `rg "scoring_sequence"` 查找这个字段的所有使用位置，区分“写入者”和“读取者”。
3. 选一个你认为默认值风险较高的 hydrator，写下如果它失败，后续可能出现什么用户可见问题。
