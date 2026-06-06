#import "../style.typ": *

== Candidate Hydration，把候选补成可判断的对象

Source 返回的候选通常很瘦。它可能只有 tweet id、author id、served type。这样的对象还不能安全展示，也不能充分排序。Candidate hydrator 的职责就是批量补字段。

=== Hydrator 的合约

#codepath("candidate-pipeline/hydrator.rs") 里有一个非常重要的约束：

```rust
/// IMPORTANT: The returned vector must have the same candidates in the same order as the input.
/// Dropping candidates in a hydrator is not allowed - use a filter stage instead.
async fn hydrate(&self, query: &Q, candidates: &[C]) -> Vec<Result<C, String>>;
```

这句话是理解 hydrator 的关键。hydrator 只能补字段，不能删候选。删除候选是 filter 的职责。

#beginner("为什么必须保持顺序", [
  pipeline 会用 `zip` 把原候选和 hydration 结果配对。如果 hydrator 少返回一个、换了顺序或偷偷删除候选，后续字段就会写错对象。这类 bug 很隐蔽，所以框架显式检查长度。
])

=== update 和 update_all

hydrator 返回的不是完整 candidate，而是“只填了自己负责字段”的 candidate。`update` 决定如何把这些字段合并回原 candidate：

```rust
fn update(&self, candidate: &mut C, hydrated: C);
```

默认 `update_all` 会遍历每个结果，只在 `Ok(hydrated)` 时更新。失败结果会跳过，原 candidate 保持已有字段。

这个设计让每个 hydrator 有清晰边界：CoreData 只写文本和基础关系，VideoDuration 只写视频时长，LanguageCode 只写语言，不互相覆盖。

=== 例子：CoreDataCandidateHydrator

#codepath("home-mixer/candidate_hydrators/core_data_candidate_hydrator.rs") 从 TES 获取帖子 core data。它补的字段包括：

- `retweeted_user_id`
- `retweeted_tweet_id`
- `in_reply_to_tweet_id`
- `tweet_text`

注意当前代码里的一个细节：`CoreDataCacheValue` 保存了 `author_id`，但 `CoreDataCandidateHydrator::update` 写回 candidate 时只更新转帖、回复关系和文本，不写回 `author_id`。因此读这一节时不要把“cache value 里有字段”和“update 一定写字段”混为一谈；真正决定字段是否生效的是 `update`。

它实现的是 `CachedHydrator`，所以先查本地缓存；缓存没有命中时，再批量调用 TES。

```rust
match self.cache_store().get(&key).await {
    Some(value) => results[index] = Some(Ok(self.hydrate_from_cache(value))),
    None => missing_candidates.push(candidate.clone()),
}
```

缓存命中的结果直接转成 hydrated candidate；缓存未命中的候选集中起来，交给 `hydrate_from_client` 批量请求。

=== 为什么 hydration 要缓存

候选元数据经常被重复请求。同一条帖子可能在多个用户、多个刷新场景、多个召回源中出现。没有缓存时，元数据服务会承受大量重复读取。

缓存的收益：

- 降低外部服务压力。
- 降低 P50/P90 延迟。
- 在下游短暂抖动时提高成功率。

缓存的风险：

- 数据可能过期，例如帖子被删除、作者状态变化。
- 缓存 key 设计错误会污染字段。
- 缓存命中率低时，缓存层只增加复杂度。

因此缓存 hydrator 同时记录 cache hit/miss 指标。读这类代码时，指标不是附属品，而是判断设计是否有效的证据。

=== Hydration 缺失后的下一步

CoreData 可能找不到某条帖子的 metadata。它会返回默认 candidate，而不是直接删除。后续 `CoreDataHydrationFilter` 会用 `author_id != 0` 做完整性检查；这要求 source 或前序阶段已经提供有效作者字段。

这是一条清晰的职责线：

- hydrator：我尽力补字段，补不到就留下默认状态。
- filter：我根据字段状态决定候选能不能继续。

把这两者混在一起会让排查困难。你不知道候选是没被召回、补字段失败，还是被规则移除。

=== 批量请求

hydrator 往往对一批候选发批量请求：

```rust
let tweet_ids: Vec<u64> = candidates.iter().map(|c| c.tweet_id).collect();
let post_features = client.get_tweet_core_datas(tweet_ids.clone()).await;
```

批量请求比逐个请求更适合线上推荐，因为它减少网络往返和服务端调度开销。但批量也有问题：批太大可能导致单次请求慢，批太小又浪费吞吐。候选数量、批大小和超时策略需要一起设计。

=== 本节练习

1. 在 `candidate-pipeline/hydrator.rs` 中找出长度检查逻辑，解释如果 hydrator 少返回一个结果，框架如何处理。
2. 打开 `CoreDataCandidateHydrator`，列出 cache key、cache value 和 update 写入的字段。
3. 找一个非 cached hydrator，比较它和 CoreData 的失败处理方式。
