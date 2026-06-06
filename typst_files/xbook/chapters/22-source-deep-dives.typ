#import "../style.typ": *

== Source 深度导读，三种候选入口

前面已经讲过 Source 的合约。这一节带读三个代表性 source：`ThunderSource`、`PhoenixSource`、`CachedPostsSource`。它们分别代表实时关注网络、模型召回、缓存回放三种候选入口。

=== 读 Source 的四层结构

任何 source 都可以按四层拆开：

1. `enable`：当前请求是否应该运行。
2. 输入字段：它从 query 读取哪些信息。
3. 外部调用：它访问哪个系统、超时和错误如何处理。
4. candidate 构造：它给候选写入哪些初始字段。

这四层比函数名更重要。只看 source 名字，你会知道“它从哪里来”；看完四层，你才知道“它什么时候来、依赖什么、失败会怎样、返回什么”。

=== ThunderSource：关注网络召回

#codepath("home-mixer/sources/thunder_source.rs") 的 `enable` 很短：

```rust
fn enable(&self, query: &ScoredPostsQuery) -> bool {
    !query.has_cached_posts
}
```

如果已经命中 cached posts，它不运行。这是一个成本优化：缓存足够好时，不再打实时 Thunder。

它读取的 query 字段包括：

- `query.user_id`
- `query.user_features.followed_user_ids`
- `query.seen_ids`
- `query.params.get(ThunderMaxResults)`
- `query.params.get(ThunderAlgorithm)`
- `query.in_network_only`

其中 `followed_user_ids` 来自 query hydration。如果关注列表缺失，ThunderSource 的请求会退化，甚至拿不到有效 in-network 候选。

=== ThunderSource 的外部调用

ThunderSource 通过 gRPC client 调用：

```rust
let response = client
    .get_in_network_posts(request)
    .await
    .map_err(|e| format!("ThunderSource: {}", e))?;
```

这里的等待是线上延迟预算的一部分。它不是本地函数调用，而是跨服务请求。失败后整个 ThunderSource 返回 `Err`，pipeline 会跳过它的候选，但其他 source 仍可继续。

=== ThunderSource 的 candidate 构造

返回的 `LightPost` 被转成 `PostCandidate`：

```rust
PostCandidate {
    tweet_id: post.post_id as u64,
    author_id: post.author_id as u64,
    in_reply_to_tweet_id,
    retweeted_tweet_id,
    ancestors,
    served_type: Some(served_type),
    ..Default::default()
}
```

这些字段都是后续阶段的重要输入：

- `tweet_id` 用于去重、hydration、打分、日志。
- `author_id` 用于社交图过滤和作者多样性。
- reply/retweet/ancestors 用于会话处理和 served history。
- `served_type` 用于日志、分数分析和最终响应。

#tip("Source 只写必要字段", [
  ThunderSource 没有写文本、语言、安全标签和最终分。它只写 source 阶段确定知道的字段。其他信息交给后续 hydrator 和 scorer。
])

=== PhoenixSource：模型召回入口

#codepath("home-mixer/sources/phoenix_source.rs") 的 `enable` 更复杂：

```rust
(!query.is_topic_request() || query.is_bulk_topic_request())
    && (!query.params.get(EnableNewUserTopicRetrieval) || !query.has_new_user_topic_ids())
    && !query.in_network_only
    && !query.has_cached_posts
```

这段条件包含四类业务判断：

- topic request 场景是否应该走普通 Phoenix。
- 新用户话题召回是否接管。
- ranked following 请求是否禁止 OON。
- cached posts 是否已经接管。

读这种 enable 条件时，不要急着化简布尔表达式。更好的方法是把每一项翻译成业务保护。

=== PhoenixSource 的输入依赖

PhoenixSource 最关键的输入是 `retrieval_sequence`：

```rust
let sequence = query
    .retrieval_sequence
    .as_ref()
    .ok_or_else(|| "PhoenixSource: missing retrieval_sequence".to_string())?;
```

没有 retrieval sequence，它直接失败。这很合理：Phoenix Retrieval 需要用户历史来构造 user representation。如果行为序列缺失，召回请求没有足够上下文。

它还读取：

- `query.user_id`
- `query.columnar_retrieval_sequence`
- `query.params.get(PhoenixMaxResults)`
- `client_context`
- `user_context`
- cluster 和 decider

=== PhoenixSource 的新用户 cluster

`resolve_cluster` 会根据历史长度切换 cluster：

```rust
let action_count = query.retrieval_sequence
    .as_ref()
    .and_then(|s| s.metadata.as_ref())
    .map(|m| m.length)
    .unwrap_or(0);
```

如果 action_count 小于阈值，则使用新用户 cluster。这是推荐系统常见做法：新用户历史少，普通模型可能不稳，需要专门策略或模型。

=== CachedPostsSource：缓存回放

#codepath("home-mixer/sources/cached_posts_source.rs") 是最短的 source：

```rust
fn enable(&self, query: &ScoredPostsQuery) -> bool {
    query.has_cached_posts
}

async fn source(&self, query: &ScoredPostsQuery) -> Result<Vec<PostCandidate>, String> {
    Ok(query.cached_posts.clone())
}
```

它不访问外部服务，因为缓存读取已经在 `CachedPostsQueryHydrator` 中完成。它只把 query 里的 `cached_posts` 放回 source 阶段。

这个设计看起来绕，但很统一：无论候选来自实时服务、模型召回还是缓存，后续 pipeline 都通过 source 阶段接收 `Vec<PostCandidate>`。

=== 三种 source 的对比

#table(
  columns: (1.2fr, 1.6fr, 1.7fr, 2.2fr),
  inset: 5pt,
  stroke: 0.5pt + line,
  [Source], [候选来源], [关键依赖], [主要风险],
  [`ThunderSource`], [实时 in-network], [关注列表、Thunder gRPC], [关注列表缺失、Thunder 慢、候选太少。],
  [`PhoenixSource`], [OON 模型召回], [retrieval sequence、模型召回服务], [行为序列缺失、cluster 错误、召回质量下降。],
  [`CachedPostsSource`], [Redis 缓存结果], [cached_posts query 字段], [缓存过期、候选重复、上下文不匹配。],
)

=== Source 排查模板

```text
source name:
enabled:
disabled reason:
input fields:
external dependency:
timeout/failure behavior:
candidate count:
fields written:
served_type:
downstream filters likely to remove:
```

这个模板能帮你把 source 的行为从“它返回了一些候选”变成可排查事实。

=== 本节练习

1. 给 `ThunderSource` 填一份 source 排查模板。
2. 给 `PhoenixSource` 填一份 source 排查模板。
3. 假设 `query.has_cached_posts=true`，写出哪些 source 会跳过，为什么。
4. 解释为什么 `CachedPostsSource` 放在 source 阶段，而不是直接跳过 pipeline 返回。
