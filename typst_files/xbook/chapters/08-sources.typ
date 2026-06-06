#import "../style.typ": *

== Sources，候选内容从哪里来

Source 是推荐系统里最像“找素材”的阶段。它不负责把内容讲完整，也不负责最终排序；它只回答一个问题：给这个 query，先拿到哪些候选？

=== Source 的合约

#codepath("candidate-pipeline/source.rs") 的 trait 很短：

```rust
#[async_trait]
pub trait Source<Q, C>: Any + Send + Sync
where
    Q: PipelineQuery,
    C: PipelineCandidate,
{
    fn enable(&self, _query: &Q) -> bool { true }
    async fn source(&self, query: &Q) -> Result<Vec<C>, String>;
}
```

source 返回的是一批 candidate。它可以来自内存、RPC、缓存、向量检索、广告系统或其他服务。

在 `CandidatePipeline::fetch_candidates` 中，所有启用的 source 会并行运行，然后把成功结果 append 到同一个候选列表里。失败 source 会被跳过。

=== 例子一：ThunderSource

#codepath("home-mixer/sources/thunder_source.rs") 负责 in-network 候选。它读取 query 里的 `followed_user_ids`，向 Thunder 请求这些关注作者的近期帖子。

核心请求包含：

- `user_id`：当前用户。
- `following_user_ids`：关注列表。
- `max_results`：最多拿多少结果。
- `exclude_tweet_ids`：已经看过或需要排除的帖子。
- `algorithm`：Thunder 内部算法选择。

返回后，它把 `LightPost` 转成 `PostCandidate`，写入 `tweet_id`、`author_id`、reply/retweet 信息和 `served_type`。

#tip("source 不需要补全所有字段", [
  ThunderSource 返回的 candidate 只是初始形态。文本、作者资料、视频时长、语言、安全标签等可以留给后续 hydrator。
])

=== 例子二：PhoenixSource

#codepath("home-mixer/sources/phoenix_source.rs") 负责 out-of-network 的 Phoenix retrieval 候选。它读取 `retrieval_sequence`，调用 Phoenix retrieval client：

```rust
let response = self
    .phoenix_retrieval_client
    .retrieve(...)
    .await?;
```

它的 `enable` 条件比 ThunderSource 更复杂：

- topic request 的处理不同。
- 新用户话题召回可能绕开普通 PhoenixSource。
- `in_network_only` 时不启用。
- 已有 cached posts 时不启用。

这说明 source 不只是“调用外部服务”。它还承担“当前请求是否适合这个候选源”的判断。

=== 候选源的互补性

一个 feed 请求通常不会只依赖一个 source：

#table(
  columns: (1.4fr, 2fr, 2.6fr),
  inset: 6pt,
  stroke: 0.5pt + line,
  [Source], [擅长什么], [可能的问题],
  [Thunder], [关注网络、实时性、低延迟], [候选范围受关注列表限制，新用户可能不足。],
  [Phoenix Retrieval], [全局语义发现、out-of-network], [依赖行为序列和模型服务，可能受索引新鲜度影响。],
  [Topics/MOE], [按话题或专家模型扩展候选], [需要请求上下文和策略判断。],
  [CachedPosts], [复用上次结果，降低延迟], [可能新鲜度较差，需谨慎处理曝光历史。],
  [Ads/Prompts/WTF], [满足产品和商业需求], [需要混排和安全约束。],
)

互补性是推荐系统可靠性的来源之一。某个 source 质量下降时，其他 source 仍然可能提供可用结果。

=== Source 的调试方式

当 feed 空了，source 是最早要检查的地方。一个实用排查顺序：

1. query hydrator 是否补齐了 source 需要的字段？例如 `followed_user_ids`、`retrieval_sequence`。
2. source 的 `enable` 是否返回 false？检查 params、decider、request type。
3. source 的下游调用是否失败？看错误日志和 latency。
4. source 返回了多少原始候选？不要等到 filter 后才看。
5. 候选是否带了必要 id？例如 tweet id、author id、served type。

=== 候选数量不是越多越好

source 多拿候选可以提高召回率，但也会增加后续成本：

- hydrator 要补更多候选字段。
- filter 要扫描更多候选。
- scoring 模型要处理更多 candidate。
- selector 和 side effect 的数据量也会变大。

因此 source 的 `max_results` 是效果和成本之间的权衡。读参数时要问：这个值是为了召回质量、延迟预算，还是下游容量？

=== 本节练习

1. 在 `phoenix_candidate_pipeline.rs` 里找出 `sources` 列表，按 in-network、out-of-network、cache、其他系统分类。
2. 打开 `ThunderSource`，标出它依赖 query 的哪些字段。
3. 打开 `PhoenixSource`，解释它的 `enable` 条件分别在保护什么场景。

