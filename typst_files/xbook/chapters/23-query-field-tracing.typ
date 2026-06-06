#import "../style.typ": *

== 字段追踪，从一个 query 字段看完整链路

大型系统里，理解一个字段比理解一个函数更重要。字段从哪里来、被谁读取、默认值是什么、失败后会怎样，决定了系统行为。本节用几个字段示范追踪方法。

=== 字段追踪方法

追踪字段时按四步走：

1. 搜写入者：`rg "field_name ="` 或看 hydrator 的 `update`。
2. 搜读取者：`rg "field_name"`。
3. 区分阶段：query hydration、source、filter、scorer、side effect。
4. 记录默认值语义：空、None、0、false 分别代表什么。

不要只搜类型定义。字段真正的语义来自读写位置。

=== `followed_user_ids`

写入者是 #codepath("home-mixer/query_hydrators/followed_user_ids_query_hydrator.rs")：

```rust
query.user_features.followed_user_ids = hydrated.user_features.followed_user_ids;
```

读取者包括：

- `ThunderSource`：构造 `GetInNetworkPostsRequest.following_user_ids`。
- `RankingScorer`：判断新用户是否有足够关注数。
- 某些 filter 或 hydrator 可能使用关注关系判断 in-network reply。

这个字段的默认值是空列表。空列表可能有两种含义：

- 用户真的没有关注任何人。
- Social graph 调用失败，hydrator 没有更新字段。

后续代码如果无法区分这两种情况，就可能把服务失败当成新用户状态。

=== `retrieval_sequence`

写入者是 `RetrievalSequenceQueryHydrator`。读取者是 `PhoenixSource`。

PhoenixSource 对它的态度很强硬：

```rust
.ok_or_else(|| "PhoenixSource: missing retrieval_sequence".to_string())?
```

也就是说缺失时 PhoenixSource 失败，不返回候选。pipeline 仍可依赖 Thunder 或缓存等其他 source，但 OON 召回会缺失。

字段语义：

- `Some(sequence)`：可以构造用户向量。
- `None`：召回缺少上下文，不应该静默发空序列。

=== `scoring_sequence`

写入者是 `ScoringSequenceQueryHydrator`。读取者是 `PhoenixScorer`。

PhoenixScorer 对缺失 scoring sequence 的处理是：

```rust
if query.scoring_sequence.is_none() {
    return vec![Ok(PostCandidate::default()); candidates.len()];
}
```

这意味着它不会失败整个 scorer，而是给每个候选返回默认更新。后续 `RankingScorer` 仍会运行，但缺少 Phoenix 预测时，许多 action score 是 None，最终分会受影响。

这和 `retrieval_sequence` 的策略不同。原因是它们处在不同阶段：retrieval sequence 缺失时 source 无法产生候选；scoring sequence 缺失时候选已经存在，系统可能仍希望用默认分或其他 scorer 继续。

=== `has_cached_posts`

写入者是 `CachedPostsQueryHydrator`。它读取 Redis，只有 cached posts 数量达到阈值才设为 true：

```rust
let has_cached_posts = cached_posts.len() >= MIN_CACHED_POSTS_THRESHOLD;
```

读取者很多：

- `ThunderSource::enable`：cached true 时跳过。
- `PhoenixSource::enable`：cached true 时跳过。
- `CoreDataCandidateHydrator::enable`：cached true 时跳过。
- `CachedPostsSource::enable`：cached true 时运行。
- `RedisPostCandidateCacheSideEffect::enable`：cached true 时不再写缓存。

这个字段相当于一个模式切换开关。它让 pipeline 从“实时召回 + hydration + scoring”切到“缓存候选回放”。

=== `author_id`

`author_id` 主要由 source 初始写入。`CoreDataCandidateHydrator` 的 cache value 保存了 `author_id`，但当前 `update` 不把它写回 candidate，所以读代码时要以 `update` 为准。这个字段被多个阶段使用：

- `CoreDataHydrationFilter` 用 `author_id != 0` 判断 core data 是否有效。
- `AuthorSocialgraphFilter` 用它检查屏蔽和静音。
- `RankingScorer` 用它做作者多样性。
- 日志和 served history 需要记录 author id。

因此 `author_id=0` 不是普通作者，而是缺失或无效信号。这个约定必须贯穿 source、hydrator 的 update 逻辑和 filter。

=== `score`

`score` 由 `RankingScorer` 写入，`TopKScoreSelector` 读取：

```rust
candidate.score.unwrap_or(f64::NEG_INFINITY)
```

缺失 score 被当成负无穷，而不是 0。这个默认值很重要：没有打分的候选不应该意外排在正常候选前面。

=== 字段追踪表

#table(
  columns: (1.4fr, 1.8fr, 1.8fr, 2.3fr),
  inset: 5pt,
  stroke: 0.5pt + line,
  [字段], [写入者], [主要读取者], [缺失风险],
  [`followed_user_ids`], [FollowedUserIdsQueryHydrator], [ThunderSource、RankingScorer], [in-network 候选不足，新用户判断失真。],
  [`retrieval_sequence`], [RetrievalSequenceQueryHydrator], [PhoenixSource], [OON 召回失败。],
  [`scoring_sequence`], [ScoringSequenceQueryHydrator], [PhoenixScorer], [模型预测缺失，最终分质量下降。],
  [`has_cached_posts`], [CachedPostsQueryHydrator], [多个 enable 条件], [pipeline 路径切错。],
  [`author_id`], [Source，CoreData cache value 只作辅助证据], [Filter/Scorer/Log], [误过滤、误排序、日志缺字段。],
  [`score`], [RankingScorer], [TopKScoreSelector], [候选无法正常排序。],
)

=== 本节练习

1. 用 `rg "has_cached_posts"` 搜索所有读取者，画出 cached 模式切换图。
2. 用 `rg "author_id"` 搜索 `home-mixer/filters`，找出哪些 filter 依赖作者字段。
3. 选择一个字段，写出它的“默认值是否安全”分析。
