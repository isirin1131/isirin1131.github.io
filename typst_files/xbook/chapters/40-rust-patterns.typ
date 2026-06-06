#import "../style.typ": *

== 给新手的 Rust 读法

这个项目的服务层大量使用 Rust。新手如果只会 Python 或 JavaScript，第一次读 trait、generic、Arc、Box、async_trait 会很吃力。本节只讲读这个项目需要的最小 Rust 知识。

=== Trait 是组件合约

`Source<Q, C>`、`Hydrator<Q, C>`、`Filter<Q, C>`、`Scorer<Q, C>` 都是 trait。你可以先把 trait 理解成“组件必须实现的方法列表”。

例如 Source：

```rust
async fn source(&self, query: &Q) -> Result<Vec<C>, String>;
```

任何实现 Source 的组件，都能被 pipeline 当作候选源运行。pipeline 不关心具体是 ThunderSource 还是 PhoenixSource，只关心它能返回 `Vec<C>`。

=== 泛型 Q 和 C

`Q` 是 query 类型，`C` 是 candidate 类型。这样同一个 `candidate-pipeline` 框架能服务不同业务：

- `ScoredPostsQuery + PostCandidate`
- `ScoredPostsQuery + FeedItem`

新手读泛型时，不要被语法吓到。回到具体 pipeline 实例，把 Q/C 替换成真实类型即可。

=== `Box<dyn Trait>`

`Vec<Box<dyn Source<ScoredPostsQuery, PostCandidate>>>` 表示一个列表，里面可以放不同具体类型的 source，只要它们都实现同一个 trait。

这让 `PhoenixCandidatePipeline` 可以把 `ThunderSource`、`PhoenixSource`、`CachedPostsSource` 放在同一个 `sources` 列表里。

=== `Arc`

`Arc<T>` 是线程安全引用计数指针。项目里很多 client 用 `Arc` 包起来，因为多个组件或异步任务需要共享同一个 client。

例如：

```rust
Arc<dyn PhoenixPredictionClient + Send + Sync>
```

可以理解成“可在线程间共享的 Phoenix client 接口”。

=== `async_trait`

Rust 原生 async trait 有限制，因此项目使用 `tonic::async_trait`。你会看到：

```rust
#[async_trait]
impl Source<ScoredPostsQuery, PostCandidate> for PhoenixSource {
    async fn source(&self, query: &ScoredPostsQuery) -> Result<Vec<PostCandidate>, String> {
        ...
    }
}
```

读法很简单：这个组件实现了异步 source 方法。

=== `Result` 和 `Option`

`Result<T, String>` 表示成功或错误。`Option<T>` 表示有或没有。

常见模式：

```rust
.await.map_err(|e| e.to_string())?
```

表示等待外部调用，失败时把错误转成字符串并返回。

```rust
candidate.score.unwrap_or(f64::NEG_INFINITY)
```

表示 score 缺失时使用默认值。读默认值时要问业务语义。

=== `..Default::default()`

构造部分字段时常见：

```rust
PostCandidate {
    tweet_id,
    author_id,
    ..Default::default()
}
```

这表示其他字段使用默认值。推荐系统里这很常见，因为每个阶段只写自己负责的字段。

=== `partition`

filter 中常见：

```rust
let (kept, removed) = candidates.into_iter().partition(|c| predicate(c));
```

注意返回顺序取决于 predicate。`partition(|c| c.author_id != 0)` 得到 `(kept, removed)`；`partition(|c| should_drop(...))` 得到的第一个是 removed，需要看变量名。

=== 本节练习

1. 把 `Source<Q, C>` 中的 Q/C 替换成 `ScoredPostsQuery/PostCandidate`，手写一遍签名。
2. 找一个 `..Default::default()`，列出哪些字段被默认化。
3. 找三个 `unwrap_or`，解释默认值的业务含义。

