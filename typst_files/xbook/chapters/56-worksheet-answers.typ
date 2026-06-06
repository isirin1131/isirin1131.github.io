#import "../style.typ": *

== 练习参考答案

本附录给的是“可核对的参考思路”，不是唯一答案。推荐系统题目通常要结合代码、参数和指标判断；如果你的答案能指出代码位置、输入输出和失败影响，即使表达不同，也可以视为合格。

=== 使用方式

先自己答，再看参考答案。每道题至少补三类证据：

- 代码证据：对应文件、trait、字段或函数。
- 数据证据：输入数量、输出数量、过滤率、错误率、延迟或缓存命中率。
- 推理证据：为什么这个现象会从上一阶段传到下一阶段。

只写“模型坏了”“缓存坏了”“下游慢了”都不够。合格答案要能沿着 query -> candidates -> hydrated candidates -> filtered candidates -> scored candidates -> selected candidates -> side effects 推下去。

=== 工作簿练习 1：端到端流程

参考流程：

```text
For You request
  -> QueryBuilder::build
  -> ForYouCandidatePipeline::execute
  -> ScoredPostsSource
  -> ScoredPostsServer::get_scored_posts / run_pipeline
  -> PhoenixCandidatePipeline::execute
  -> PostCandidate 列表
  -> candidates_to_scored_posts
  -> FeedItem::Post
  -> AdsSource / WhoToFollowSource / PromptsSource / PushToHomeSource
  -> BlenderSelector
  -> final FeedItem 列表
  -> For You side effects
```

关键边界：

- `PhoenixCandidatePipeline` 的候选类型是 `PostCandidate`，它主要服务帖子推荐。
- `ForYouCandidatePipeline` 的候选类型是 `FeedItem`，它把帖子、广告、关注推荐、prompt、push-to-home 等 item 放进同一条 feed。
- side effects 不决定当前返回顺序，但会写入日志、served history、client events 和后续闭环状态。

=== 工作簿练习 2：追踪 `has_cached_posts`

写入者是 `CachedPostsQueryHydrator`。它从 Redis 读取缓存，反序列化成 `cached_posts`，当缓存条数达到阈值时设置 `has_cached_posts=true`。

典型读取者：

- `CachedPostsSource`：只有 `has_cached_posts=true` 时启用，把缓存候选重新接回 source 阶段。
- `ThunderSource`、`PhoenixSource`、`PhoenixTopicsSource`、`PhoenixMOESource`、`TweetMixerSource`：通常在缓存命中时跳过实时召回。
- `PhoenixScorer`：缓存命中时不再调用 Phoenix prediction。
- `RedisPostCandidateCacheSideEffect`、`ScoredStatsSideEffect` 等：会根据缓存路径改变写入或统计逻辑。

解释时要写清权衡：缓存路径降低实时依赖和延迟压力，但有新鲜度、重复内容和过期候选风险；实时路径更新鲜，但依赖更多外部系统。

=== 工作簿练习 3：模拟 filter pipeline

如果 10 个候选的条件完全不重叠：

```text
10
- 2 duplicate
剩 8
- 1 author_id=0
剩 7
- 2 blocked author
剩 5
- 1 visibility drop
剩 4
```

但真实答案不能只做减法。过滤器顺序会改变每一步输入；同一个候选可能既重复又来自 blocked author。正确写法是记录每个 filter 的 input、kept、removed，再解释总 removed 为什么可能小于各条件数量之和。

=== 工作簿练习 4：手算分数

可以自定义一组权重，例如：

```text
score = 1.0 * fav + 2.0 * reply + 0.5 * dwell - 3.0 * not_interested
```

代入：

```text
A = 0.2 + 0.02 + 0.15 - 0.03 = 0.34
B = 0.1 + 0.16 + 0.25 - 0.06 = 0.45
C = 0.05 + 0.04 + 0.10 - 0.30 = -0.11
```

排序是 B > A > C。如果把 `not_interested` 权重从 -3.0 改成 -8.0：

```text
A = 0.2 + 0.02 + 0.15 - 0.08 = 0.29
B = 0.1 + 0.16 + 0.25 - 0.16 = 0.35
C = 0.05 + 0.04 + 0.10 - 0.80 = -0.61
```

C 下降最明显。这个练习的重点不是这组权重本身，而是理解负反馈权重会改变排序目标，不能当作无害的后处理。

=== 工作簿练习 5：设计 source

合格设计至少包含：

- enable 条件，例如参数开关、缓存路径、用户状态、in-network-only 约束。
- 依赖的 query 字段，例如 user id、topic ids、retrieval sequence、followed user ids。
- 外部 client、timeout 和错误处理。
- max results、去重策略和候选量指标。
- 返回字段，至少要有 `tweet_id`、`served_type`，如果 source 已知道作者或 in-network 信息，也可以提前写入。
- 失败策略，通常是返回 `Err` 并让 pipeline 跳过该 source 的候选，而不是让整个 feed 失败。

不合格设计的典型问题：在 source 里做大量安全过滤、没有 enable 条件、没有候选数量指标、把默认空列表和下游失败混在一起。

=== 工作簿练习 6：空结果 Runbook

参考 10 步：

1. 确认请求是否进入 `ScoredPostsServer` 和目标 pipeline。
2. 查看 `QueryBuilder::build` 是否短路或构造默认 query。
3. 查看 query hydrator 的 enabled、error、latency。
4. 检查关键字段：`scoring_sequence`、`retrieval_sequence`、`followed_user_ids`、`has_cached_posts`。
5. 查看每个 source 的 enabled 和 candidate_count。
6. 检查 hydration 长度是否匹配，missing 或默认字段是否异常。
7. 查看每个 filter 的 input、kept、removed，找最大移除点。
8. 检查 scorer 是否写入 `score`，Phoenix prediction 是否失败。
9. 检查 selector 输入数量、selected 数量和 `score=None` 比例。
10. 检查 post-selection filter，尤其是 visibility 和 safety。

结论必须指出“第一个异常阶段”，而不是只描述最终为空。

=== 工作簿练习 7：安全默认值

参考分析：

- `visibility_reason=None` 在 `VFFilter` 中会保留候选；这表示没有收到 drop reason，但如果 VF hydrator 失败率升高，它也可能掩盖安全检查缺失。
- `author_blocks_viewer=None` 不能简单等于 false；要看对应 hydrator 是否成功，以及 filter 如何解释缺失。
- `brand_safety_verdict=None` 对广告混排风险较高，必须结合 ads brand safety hydrator 和广告日志判断。

结论：默认值是否安全不是字段类型决定的，而是由“谁写、失败时是否写、filter 如何解释、有没有监控”共同决定。

=== 工作簿练习 8：读一个 side effect

以 `ServedCandidatesKafkaSideEffect` 为例，答案应覆盖：

- enable 条件：是否对当前 query 启用。
- 输入：side effect input 包含 final selected 和 non-selected candidates。
- 写入：把服务过的候选事实发布到 Kafka，供分析、训练、审计或回放使用。
- 当前影响：失败通常不改变当前响应，因为 side effects 在 pipeline 最后后台执行。
- 后续影响：日志缺失会影响实验分析、训练样本、served history 或问题排查。

如果选择 Redis 缓存 side effect，则要说明它影响下一次请求是否走缓存路径。

=== 工作簿练习 9：本地 Phoenix demo

`phoenix/run_pipeline.py` 是学习 Phoenix 的本地路径，不等同线上 Home Mixer。

参考流程：

1. 加载 artifacts 和模型配置。
2. 构造用户历史、候选 corpus 和 hash 输入。
3. retrieval model 输出 user representation。
4. 与 corpus representation 点积，取 top K。
5. ranking model 对 top K 预测多行为概率。
6. 本地用简单 weighted score 排序并打印结果。

差异：

- 本地 demo 不包含 Home Mixer 的 query hydrator、source enable、hydrator、filter、selector、side effect。
- 线上 `PhoenixSource` 和 `PhoenixScorer` 走服务调用，且受参数、decider、timeout、fallback 和缓存路径影响。
- 本地 weighted score 用于演示，线上 `RankingScorer` 的权重、归一化、多样性和 OON 调整更完整。

=== 工作簿练习 10：复盘

参考复盘骨架：

- 影响范围：OON 候选下降，可能影响 For You 中非关注网络内容占比和探索性。
- 根因：`retrieval_sequence` 缺失导致 Phoenix retrieval source 无法正常构造请求，相关 source 返回错误或候选减少。
- 发现不足：只监控最终 result size 不够，缺少 query hydrator 字段填充率、source error、source candidate_count 分布。
- 修复：恢复 retrieval sequence hydrator 或下游依赖；增加字段缺失告警；必要时临时调低依赖该 source 的流量。
- 长期防护：为关键 query 字段建立 dashboard，把 source 级候选占比、错误率和空返回率纳入发布检查。

=== 复习题参考：架构

1. Home Mixer 负责线上请求编排、pipeline 配置、候选融合和 side effects；Phoenix 负责 retrieval/ranking 模型能力和预测信号。
2. 内层 `PhoenixCandidatePipeline` 产出帖子候选和分数；外层 `ForYouCandidatePipeline` 把帖子与广告、关注推荐、prompt、push-to-home 等混成最终 feed。
3. `PostCandidate` 是帖子候选在 pipeline 内部的工作对象；`FeedItem` 是最终 feed 可以承载的展示 item，可能是帖子，也可能是广告或模块。
4. Thunder 偏实时 in-network 候选，Phoenix Retrieval 偏基于用户兴趣向量的候选召回；两者互补。

=== 复习题参考：Pipeline

1. 顺序是 query hydration、dependent query hydration、source、candidate hydration、filter、scorer、selector、post-selection hydration、post-selection filter、truncate/finalize、side effects。
2. query hydrator、source、hydrator、side effect 内部可并行；filter 和 scorer 按配置顺序执行；selector 是一次决策。
3. filter 会改变下一个 filter 的输入，也要保留 removed 归因。独立并行删除会让“谁移除了候选”变得不清楚。
4. side effect 放最后，是因为它通常写日志、缓存或状态，不应阻塞当前响应；但失败会影响未来闭环，所以必须监控。

=== 复习题参考：Query

1. 原始请求通常提供 user id、请求上下文、产品 surface、topic/exclude 等直接参数。
2. query hydrator 补行为序列、关注/屏蔽/静音关系、缓存候选、served history、IP、用户特征等。
3. `params` 是参数和实验配置的读取入口；`decider` 更像运行时开关或流量决策入口。
4. `has_cached_posts` 会让系统从实时召回路径切到缓存回放路径，因此影响 source、scorer 和 side effect。

=== 复习题参考：Candidate

1. 一个 source 至少要写清候选 id 和类型，实际代码里常见字段是 `tweet_id`、`served_type`，有能力时再补 `author_id`、`in_network` 等。
2. `author_id=0` 在 `CoreDataHydrationFilter` 语境中表示候选缺少有效作者 id，会被当作完整性失败处理，候选不应继续。
3. `get_original_tweet_id` 用于把转帖等包装关系还原到原始内容，便于预测、去重、可见性和日志一致。
4. `TopKScoreSelector` 把 `score=None` 当作 `f64::NEG_INFINITY`，因此未打分候选不会排在正常打分候选前面。

=== 复习题参考：Phoenix

1. Retrieval 用 two-tower，是为了把用户和候选投到同一向量空间，并让候选向量可以提前计算或索引。
2. Candidate isolation 避免一个候选的预测依赖同批次其他候选，减少批次组成对分数的干扰。
3. 多行为预测能同时表达点赞、回复、停留、关注、负反馈等目标，比单一 relevance 更接近 feed 的真实目标。
4. 本地 `run_pipeline.py` 演示模型输入输出；线上 Home Mixer 还包含 query hydration、source enable、外部服务调用、filter、selector、side effects、参数和降级。

=== 复习题参考：生产

1. source 失败时，该 source 不贡献候选；其他成功 source 仍可继续，错误通过日志和指标暴露。
2. query hydrator 失败会让字段保持默认，风险是默认空值和真实空值混淆，后续 source/scorer 可能误判。
3. side effect 失败不一定影响当前响应，但会损害缓存、日志、训练样本、实验分析和 served history。
4. final result size 突降时，按阶段查看：query 字段填充率、source candidate_count、hydration missing、filter removed、score missing、selector selected、post-selection removed。

=== 复习题参考：开放题

新增 source 的指标优先级：

- enabled_count、request_count、success/error、latency。
- candidate_count 分布、empty_count、timeout_count。
- served_type 占比、最终 selected 占比。
- 下游 filter removed 占比，避免 source 只制造噪声。

负反馈上升可以先查三层：

- 数据层：曝光、点击、not interested、report 等 label 是否正常。
- 排序层：负反馈权重、OON 调整、多样性、归一化是否变化。
- 候选层：某个 source 占比是否异常，安全/可见性过滤是否漏掉高风险内容。

缓存命中后重复内容的可能原因：

- Redis 缓存写入时包含已服务或重复候选。
- served history side effect 失败或延迟。
- cache key 维度不足，导致不同上下文复用同一批候选。
- `CachedPostsSource` 回放后缺少必要去重或过滤。

P99 升高但 P50 不变，通常说明尾部依赖变慢、超时重试、少量大用户候选量过高、缓存 miss 放大，或下游服务存在限流和排队。

=== 调试场景题参考

OON 内容消失：

- 先查 `PhoenixSource`、`PhoenixTopicsSource`、`PhoenixMOESource`、`TweetMixerSource` 是否启用和返回候选。
- 再查 `retrieval_sequence` 是否缺失、Phoenix retrieval client 是否错误、OON 权重是否被调低。
- 最后查 post-selection safety 是否集中移除了 OON。

视频内容变少：

- 查 `exclude_videos`、`VideoFilter`、视频时长 hydrator、媒体 hydrator。
- 对比 source 阶段视频占比和 filter 后视频占比，定位是召回减少还是过滤增加。

缓存命中后质量下降：

- 查 `has_cached_posts` 命中率、缓存年龄、缓存写入候选数量。
- 对比缓存路径和实时路径的 source 组成、score 分布、重复率。
- 检查 Redis 写入 side effect 是否写入了过期或低质量候选。

新用户结果空：

- 查 QueryBuilder 是否识别新用户路径。
- 查 retrieval/ranking sequence 默认值、新用户 cluster、Thunder 关注列表、topic source。
- 检查 filters 是否把默认字段误判成无效字段。

P99 延迟升高：

- 先看 stage latency 分位数，不只看平均值。
- 查 source、hydrator、scorer 的慢依赖和 timeout。
- 对比 cache hit/miss、候选数量、batch size 和下游限流。

实验指标无法解释：

- 先确认实验分桶、params、decider 是否按预期生效。
- 查日志 side effect 是否完整，避免样本缺失。
- 对比每个阶段的 candidate_count 和 item type distribution，避免把数据链路问题误判成策略效果。
