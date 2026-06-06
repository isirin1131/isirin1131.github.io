#import "../style.typ": *

== 组件目录，给代码建立索引

读大型推荐系统时，最容易迷路的原因不是代码太难，而是不知道每个文件属于哪一段流程。本节把 `PhoenixCandidatePipeline` 和 `ForYouCandidatePipeline` 中出现的主要组件整理成目录。它不是最终 API 文档，而是读码索引。

=== 帖子候选流水线的组件

#codepath("home-mixer/candidate_pipeline/phoenix_candidate_pipeline.rs") 配置了帖子候选的主流程。

#table(
  columns: (1.2fr, 2.4fr, 2.8fr),
  inset: 5pt,
  stroke: 0.5pt + line,
  [阶段], [组件], [主要作用],
  [Query], [`ScoringSequenceQueryHydrator`], [补排序模型使用的用户行为序列。],
  [Query], [`RetrievalSequenceQueryHydrator`], [补召回模型使用的用户行为序列。],
  [Query], [`BlockedUserIdsQueryHydrator`], [补 viewer 屏蔽列表。],
  [Query], [`MutedUserIdsQueryHydrator`], [补 viewer 静音列表。],
  [Query], [`FollowedUserIdsQueryHydrator`], [补关注列表，供 Thunder 和新用户逻辑使用。],
  [Query], [`SubscribedUserIdsQueryHydrator`], [补订阅关系。],
  [Query], [`CachedPostsQueryHydrator`], [读取缓存候选，支持降延迟或回退。],
  [Query], [`MutualFollowQueryHydrator`], [补互关信息。],
  [Query], [`UserDemographicsQueryHydrator`], [补用户画像类上下文。],
  [Query], [`FollowedGrokTopicsQueryHydrator`], [补关注的话题。],
  [Query], [`FollowedStarterPacksQueryHydrator`], [补 starter pack 相关上下文。],
  [Query], [`InferredGrokTopicsQueryHydrator`], [补推断话题。],
  [Query], [`ImpressionBloomFilterQueryHydrator`], [补曝光去重相关结构。],
  [Query], [`IpQueryHydrator`], [补 IP 地理信息。],
  [Query], [`UserInferredGenderQueryHydrator`], [补推断性别信息。],
)

=== Source 目录

#table(
  columns: (1.5fr, 2.5fr, 2.2fr),
  inset: 5pt,
  stroke: 0.5pt + line,
  [Source], [候选来源], [新手重点],
  [`ThunderSource`], [关注网络的实时帖子], [依赖 followed_user_ids，适合理解 in-network。],
  [`TweetMixerSource`], [其他帖子混合服务], [适合理解跨服务候选接入。],
  [`PhoenixSource`], [Phoenix 普通 out-of-network 召回], [重点看 retrieval_sequence 和 enable 条件。],
  [`PhoenixTopicsSource`], [话题相关 Phoenix 召回], [关注 topic request 场景。],
  [`PhoenixMOESource`], [专家模型或 MoE 召回], [关注多路召回策略。],
  [`CachedPostsSource`], [缓存候选], [关注缓存命中后如何跳过昂贵阶段。],
)

Source 的共同问题是：它返回多少候选、候选带什么初始字段、失败时是否允许降级。

=== Candidate Hydrator 目录

#table(
  columns: (1.7fr, 3.1fr),
  inset: 5pt,
  stroke: 0.5pt + line,
  [Hydrator], [补充字段],
  [`InNetworkCandidateHydrator`], [标记候选是否来自关注网络。],
  [`CoreDataCandidateHydrator`], [帖子文本、作者、回复、转帖等核心数据。],
  [`QuoteHydrator`], [quote 相关帖子与作者信息。],
  [`VideoDurationCandidateHydrator`], [视频时长。],
  [`HasMediaHydrator`], [是否有媒体。],
  [`SubscriptionHydrator`], [订阅内容相关字段。],
  [`GizmoduckCandidateHydrator`], [作者用户资料。],
  [`BlockedByHydrator`], [作者是否屏蔽 viewer。],
  [`FilteredTopicsHydrator`], [候选的话题过滤信息。],
  [`LanguageCodeHydrator`], [语言信息。],
)

post-selection hydrator 则更靠近最终展示：

- `VFCandidateHydrator`：可见性过滤需要的信息。
- `AdsBrandSafetyHydrator`、`AdsBrandSafetyVfHydrator`：广告安全相关。
- `TweetTypeMetricsHydrator`：帖子类型指标。
- `FollowingRepliedUsersHydrator`：回复关系。
- `MutualFollowJaccardHydrator`：互关相似度。

=== Filter 目录

filter 数量多，说明线上推荐需要大量硬约束。可以按意图分类：

#table(
  columns: (1.3fr, 3.4fr),
  inset: 5pt,
  stroke: 0.5pt + line,
  [类别], [组件],
  [去重], [`DropDuplicatesFilter`、`RetweetDeduplicationFilter`、`DedupConversationFilter`],
  [数据完整性], [`CoreDataHydrationFilter`],
  [时间], [`AgeFilter`],
  [用户关系], [`SelfTweetFilter`、`AuthorSocialgraphFilter`],
  [曝光历史], [`PreviouslySeenPostsFilter`、`PreviouslySeenPostsBackupFilter`、`PreviouslyServedPostsFilter`],
  [内容资格], [`IneligibleSubscriptionFilter`、`VideoFilter`、`TopicIdsFilter`、`NewUserTopicIdsFilter`],
  [用户控制], [`MutedKeywordFilter`],
  [可见性], [`VFFilter`、`AncillaryVFFilter`],
)

读 filter 时要问：它保护谁？保护 viewer、作者、平台安全、产品体验，还是系统成本？

=== Scorer 和 Selector 目录

帖子候选流水线的 scorer：

- `PhoenixScorer`：调用 Phoenix prediction client，写入多行为预测。
- `RankingScorer`：加权多行为预测，加入多样性和 OON 调整，写入最终 score。
- `VMRanker`：调用外部 ranker，作为额外排序信号或重排环节。

selector：

- `TopKScoreSelector`：按 `candidate.score` 排序并截断。

外层 For You pipeline 的 selector：

- `BlenderSelector`：先 partition posts/ads/prompts/wtf/push-to-home，再按产品规则混排。

=== Side Effect 目录

帖子候选流水线 side effects：

- `PhoenixExperimentsSideEffect`
- `RerankingKafkaSideEffect`
- `RedisPostCandidateCacheSideEffect`
- `ScoredStatsSideEffect`
- `MutualFollowStatsSideEffect`
- `PhoenixRequestCacheSideEffect`

外层 feed side effects：

- `AdsInjectionLoggingSideEffect`
- `PublishSeenIdsToKafkaSideEffect`
- `ServedCandidatesKafkaSideEffect`
- `ClientEventsKafkaSideEffect`
- `ForYouResponseStatsSideEffect`
- `UpdatePastRequestTimestampsSideEffect`
- `UpdateServedHistorySideEffect`
- `TruncateServedHistorySideEffect`

side effect 是理解闭环的关键。它们把“本次推荐发生了什么”写回系统，供后续请求、训练、实验和分析使用。

=== 如何使用这个目录

遇到新文件时，先把它放到上面的分类里。然后按统一模板阅读：

```text
阶段：
输入字段：
输出字段：
外部依赖：
enable 条件：
失败策略：
关键指标：
用户可见影响：
```

这样你不会被文件数量淹没，也不会只停留在函数名层面。

