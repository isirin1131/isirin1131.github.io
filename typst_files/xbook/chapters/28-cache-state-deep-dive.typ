#import "../style.typ": *

== 缓存和状态，推荐为什么要记住过去

推荐系统不是无状态函数。它要记住刚刚展示过什么、缓存哪些高分候选、用户最近请求过几次、哪些内容已经看过。本节看 cached posts 和 served history 两条状态链路。

=== CachedPostsQueryHydrator：读缓存

#codepath("home-mixer/query_hydrators/cached_posts_query_hydrator.rs") 从 Redis 读缓存候选。它有两个关键参数：

```rust
const MIN_CACHED_POSTS_THRESHOLD: usize = 500;
const REDIS_GET_TIMEOUT: Duration = Duration::from_millis(300);
```

这说明缓存命中不是只看 Redis 有无 payload。只有候选数量达到阈值，才认为 `has_cached_posts=true`。

为什么需要阈值？因为缓存里如果只有很少候选，直接走 cached path 可能导致 feed 供给不足。阈值让系统在缓存不够完整时回到实时召回路径。

=== 读缓存的失败策略

Redis GET 被 `timeout` 包住：

```rust
tokio::time::timeout(REDIS_GET_TIMEOUT, self.redis_client.get(cache_key.clone())).await
```

超时或错误时 hydrator 返回 Err。pipeline 不会更新 cached_posts，也不会设 `has_cached_posts`。于是后续 source 会按实时路径运行。

这是一种合理降级：缓存是优化，不是唯一数据源。

=== CachedPostsSource：把缓存重新接回 source 阶段

如果 `has_cached_posts=true`，`CachedPostsSource` 运行，其他昂贵 source 通常跳过。这样 pipeline 后面仍然处理 `Vec<PostCandidate>`，不需要为缓存路径写另一套主流程。

缓存路径的好处：

- 降低实时召回和模型服务压力。
- 降低延迟。
- 在部分下游不稳定时提供可用结果。

缓存路径的风险：

- 新鲜度下降。
- 用户刚看过的内容可能重复。
- 参数或请求上下文变了，缓存候选可能不再适合。

=== RedisPostCandidateCacheSideEffect：写缓存

#codepath("home-mixer/side_effects/redis_post_candidate_cache_side_effect.rs") 在响应后写缓存。它会从 selected 和 non_selected 中挑选 weighted_score 大于 0 的候选，并按分数排序截断。

这说明缓存的不只是最终展示内容，也可以缓存高质量但未展示候选。下一次请求可以更快拿到一批候选。

它还使用 zstd 压缩，并设置 TTL：

```rust
const REDIS_TTL_SECONDS: u64 = 180;
const ZSTD_COMPRESSION_LEVEL: i32 = 6;
```

TTL 代表缓存只服务短期复用，不是长期存储。

=== Served history：避免短期重复

#codepath("home-mixer/side_effects/update_served_history_side_effect.rs") 会把最终 FeedItem 写入 served history。它支持不同 item 类型：

- Post
- Ad
- WhoToFollow
- Prompt
- PushToHome

对 Post，如果有 ancestors，会把祖先和当前 tweet 都写入。这能帮助后续请求避免展示同一会话的重复分支。

=== 状态的两种用途

#table(
  columns: (1.4fr, 2.2fr, 2.3fr),
  inset: 5pt,
  stroke: 0.5pt + line,
  [状态], [用途], [风险],
  [cached posts], [复用高分候选，降低延迟和成本。], [过期、重复、上下文不匹配。],
  [served history], [短期去重和会话控制。], [写入失败导致重复展示。],
  [past request timestamps], [控制请求频率或刷新逻辑。], [状态不准导致策略误判。],
  [seen ids], [排除已看内容。], [客户端和服务端视图不一致。],
)

=== 状态一致性

状态系统经常是最终一致的。side effect 写入在后台执行，可能晚于响应，也可能失败。下一次请求可能读到旧状态。

因此状态逻辑要能容忍：

- 刚写的状态还没读到。
- 某次写入失败。
- 不同存储之间不一致。
- 缓存内容和最新可见性不一致。

这也是为什么最终可见性 filter 不能因为 cached posts 命中就完全跳过。

=== 本节练习

1. 画出 cached posts 的读路径和写路径。
2. 解释 `MIN_CACHED_POSTS_THRESHOLD` 保护了什么。
3. 解释为什么缓存 selected 和 non_selected 都有意义。
4. 分析 served history 写入失败会造成哪些用户可见问题。

