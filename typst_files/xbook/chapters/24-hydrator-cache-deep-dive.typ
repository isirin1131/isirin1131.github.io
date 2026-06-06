#import "../style.typ": *

== CachedHydrator 深度导读

Hydrator 经常访问外部服务。为了降低延迟和下游压力，框架提供了 `CachedHydrator`。这一节带读它的控制流，并解释为什么缓存逻辑要写在抽象层。

=== CachedHydrator 的角色

普通 Hydrator 只定义：

```rust
async fn hydrate(&self, query: &Q, candidates: &[C]) -> Vec<Result<C, String>>;
```

CachedHydrator 拆得更细：

```rust
fn cache_key(&self, candidate: &C) -> Self::CacheKey;
fn hydrate_from_cache(&self, value: Self::CacheValue) -> C;
async fn hydrate_from_client(&self, query: &Q, candidates: &[C]) -> Vec<Result<C, String>>;
fn cache_value(&self, hydrated: &C) -> Self::CacheValue;
```

它把“查缓存、找 miss、批量打 client、写回缓存”的模板统一起来。具体 hydrator 只需要定义 key/value 和如何访问 client。

=== 控制流

`CachedHydrator` 的默认实现大致是：

```text
for each candidate:
  key = cache_key(candidate)
  if cache hit:
    results[index] = hydrate_from_cache(value)
  else:
    collect missing candidate/key/index

if missing not empty:
  hydrated_missing = hydrate_from_client(missing_candidates)
  for each hydrated missing:
    if ok:
      cache_store.insert(key, cache_value(hydrated))
    results[index] = hydrated

return results in original order
```

关键点是保存 `missing_indices`。因为 client 只处理 miss 子集，返回结果必须放回原 candidates 的位置。

=== 为什么要保持原顺序

假设输入候选是：

```text
[A, B, C, D]
```

其中 A、C 命中缓存，B、D miss。client 只会收到 `[B, D]`。返回后必须还原成：

```text
[A_result, B_result, C_result, D_result]
```

如果错位，B 的文本可能写到 C 上，后续 filter 和 scorer 会基于错误内容决策。这类错误很难通过类型系统发现，所以框架显式用 index 合并。

=== CoreDataCandidateHydrator 的 key/value

`CoreDataCandidateHydrator` 的 cache key 是 `tweet_id`：

```rust
fn cache_key(&self, candidate: &PostCandidate) -> u64 {
    candidate.tweet_id
}
```

cache value 包含：

- author id
- retweeted user id
- retweeted tweet id
- in reply to tweet id
- tweet text

这说明缓存内容是 core data 的一个子集，不是完整 PostCandidate。缓存 value 越小，存储和序列化成本越低；但字段太少，后续可能仍需访问 client。

=== 缓存命中指标

`CachedHydrator::stat_cache` 会记录 cache hit 和 miss。读缓存逻辑时必须看指标，因为缓存是否有效不能靠感觉判断。

如果 miss 很高，可能说明：

- cache key 设计不稳定。
- TTL 太短。
- 候选重复度低。
- cache store 不健康。
- 某些请求绕过了缓存写入。

如果 hit 很高但数据错误，可能说明：

- cache value 过期。
- key 缺少上下文维度。
- 更新或删除没有同步失效。

=== 缓存和 correctness

缓存不是单纯性能优化，它会改变系统行为。CoreData 里的文本、作者关系、删除状态等如果过期，会影响过滤和展示。哪些字段可以缓存，取决于它们变化频率和错误代价。

经验上：

- 稳定字段更适合缓存，例如历史帖子文本。
- 频繁变化或安全敏感字段要谨慎缓存。
- 可见性、删除、屏蔽关系通常需要更强的新鲜度保证。

=== 本节练习

1. 在 `hydrator.rs` 中画出 CachedHydrator 的 hit/miss 控制流。
2. 分析 `CoreDataCacheValue` 中每个字段的变化频率。
3. 假设 tweet text 缓存过期，会影响哪些 filter 或日志？
4. 设计一个新的 cached hydrator，写出 cache key、cache value、失效风险。

