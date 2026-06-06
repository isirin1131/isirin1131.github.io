#import "../style.typ": *

== 请求生命周期，从 gRPC 到 Pipeline

这一节跟踪一次 scored posts 请求如何进入 Home Mixer，怎样变成 `ScoredPostsQuery`，再交给 pipeline 执行。

=== 入口：get_scored_posts

#codepath("home-mixer/server.rs") 中实现了 gRPC 方法 `get_scored_posts`。它做的第一件事是从 metadata 提取 tracing 信息：

```rust
let b3_info = extract_b3_info(request.metadata());
```

然后调用 `query_builder.build(...)`，把 proto query 转成内部 query。

这说明请求入口不应该直接进入算法。它先要做校验、trace、上下文构造和参数求值。

=== QueryBuilder::build

`QueryBuilder::build` 的关键步骤：

1. 检查 viewer_id。
2. 如果是 trace user，强制采样。
3. 获取 viewer data。
4. 判断是否 `in_network_only`。
5. evaluate feature switches。
6. 生成 prediction_id 和 request_id。
7. 构造 `ScoredPostsQuery`。
8. 创建 root span。

这一步把外部请求转换成内部系统能处理的上下文。

=== Viewer data timeout

`fetch_viewer_data` 使用 timeout：

```rust
tokio::time::timeout(
    Duration::from_millis(VIEWER_ROLES_TIMEOUT_MS),
    self.gizmoduck_client.get_viewer_data(viewer_id),
).await
```

超时或错误会返回默认 ViewerData。这是入口阶段的降级。它保护请求延迟，但也意味着角色、muted keywords、follower count 等信息可能缺失。

这里再次体现默认值风险：入口降级后，后续系统仍能跑，但个性化和过滤可能变弱。

=== Feature switches

`evaluate_feature_switches` 用 user id、country、language、client app、datacenter、账号年龄、手机号状态和 user roles 构造 recipient。然后匹配 feature switches，并应用 overrides。

也就是说参数不是全局常量，而是按用户、地区、客户端和实验动态求值。

=== ScoredPostsServer::run_pipeline

#codepath("home-mixer/scored_posts_server.rs") 的 `run_pipeline` 是进入候选 pipeline 的地方：

```rust
let pipeline_result = self.phoenix_candidate_pipeline.execute(query).await;
```

执行前它会处理 test user，记录请求信息；执行后记录响应统计，并把 `PostCandidate` 转成 `ScoredPost`。

这一步是算法 pipeline 和服务 API 的边界：

- pipeline 输出内部候选。
- server 负责日志、响应转换和 debug JSON。

=== Debug JSON

`build_debug_json` 把 query、retrieved_candidates、filtered_candidates、selected_candidates 和 stats 序列化出来。这对学习和排查很有用，因为它展示了候选在各阶段的状态。

一个好的 debug 输出应该能回答：

- query 最终补了哪些字段？
- source 总共拿到多少候选？
- 哪些候选被过滤？
- 最终选中了哪些候选？
- 各阶段数量是否合理？

=== 请求生命周期图

```text
gRPC request
  -> extract tracing metadata
  -> QueryBuilder::build
      -> fetch viewer data
      -> evaluate feature switches
      -> construct ScoredPostsQuery
      -> root span
  -> ScoredPostsServer::run_pipeline
      -> PhoenixCandidatePipeline::execute
      -> candidates_to_scored_posts
  -> gRPC response
  -> side effects continue in background
```

=== 本节练习

1. 在 `QueryBuilder::build` 中标出所有可能影响 query 的外部输入。
2. 解释 viewer data timeout 后为什么不能直接失败整个请求。
3. 打开 `build_debug_json`，说明它对排查空结果有什么帮助。
4. 画出 `ScoredPostsQuery` 从 proto query 到 hydrated query 的变化过程。

