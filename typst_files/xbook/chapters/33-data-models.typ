#import "../style.typ": *

== 数据模型剖析，Query 和 Candidate

前面的章节按阶段讲。这一节换一个角度：看两个核心数据结构 `ScoredPostsQuery` 和 `PostCandidate`。它们是推荐流水线中最重要的“运输容器”。

=== ScoredPostsQuery：一次请求的上下文

#codepath("home-mixer/models/query.rs") 中的 `ScoredPostsQuery` 很长，因为它承载了整次请求的上下文。可以分成几类：

#table(
  columns: (1.4fr, 3.2fr),
  inset: 5pt,
  stroke: 0.5pt + line,
  [类别], [字段例子],
  [请求身份], [`user_id`、`client_app_id`、`request_id`、`prediction_id`],
  [地域和客户端], [`country_code`、`language_code`、`ip_address`、`user_agent`、`client_version`],
  [请求模式], [`in_network_only`、`is_bottom_request`、`is_top_request`、`is_preview`、`is_polling`],
  [用户历史], [`scoring_sequence`、`retrieval_sequence`、`served_history`],
  [候选排除], [`seen_ids`、`served_ids`、`topic_ids`、`excluded_topic_ids`、`exclude_videos`],
  [用户特征], [`user_features`、`user_demographics`、`subscription_level`],
  [控制面], [`params`、`decider`],
  [缓存], [`cached_posts`、`has_cached_posts`],
)

这个结构说明 query 不是一个简单请求对象，而是一个逐步被 hydrator 填满的上下文。

=== Query 的构造

`ScoredPostsQuery::new` 负责把 proto query、viewer data、feature switch、设备状态等合成初始 query。很多字段一开始是默认值：

```rust
scoring_sequence: None,
retrieval_sequence: None,
cached_posts: vec![],
has_cached_posts: false,
served_history: vec![],
```

后续 query hydrator 会逐步填这些字段。读 query 时要区分：

- 请求入口已经知道的字段。
- viewer data 带来的字段。
- feature switch/decider 控制字段。
- hydrator 后补字段。

=== PostCandidate：候选的生命周期

#codepath("home-mixer/models/candidate.rs") 中的 `PostCandidate` 也很长。它从 source 阶段开始是瘦对象，经过 hydration、filter、scoring 后变胖。

可以按生命周期分类：

#table(
  columns: (1.5fr, 3.2fr),
  inset: 5pt,
  stroke: 0.5pt + line,
  [阶段], [字段例子],
  [Source 初始字段], [`tweet_id`、`author_id`、`served_type`、reply/retweet ids],
  [Core hydration], [`tweet_text`、`retweeted_user_id`、`quoted_tweet_id`],
  [Media/user hydration], [`min_video_duration_ms`、`has_media`、`author_screen_name`],
  [Safety hydration], [`visibility_reason`、`safety_labels`、`brand_safety_verdict`],
  [Social hydration], [`author_blocks_viewer`、`mutual_follow_jaccard`],
  [Scoring], [`phoenix_scores`、`weighted_score`、`score`、`prediction_request_id`],
  [Response/log], [`ancestors`、`tweet_type_metrics`、`following_replied_user_ids`],
)

这就是为什么 hydrator 和 scorer 要保持顺序和字段边界。一个字段写错，会影响多个后续阶段。

=== CandidateHelpers

`CandidateHelpers` 提供几个语义方法：

```rust
fn get_original_tweet_id(&self) -> u64 {
    self.retweeted_tweet_id.unwrap_or(self.tweet_id)
}

fn get_original_author_id(&self) -> u64 {
    self.retweeted_user_id.unwrap_or(self.author_id)
}
```

这解决 retweet 场景：展示 tweet 和原始 tweet 不是同一个 id。模型请求、去重、日志可能需要原始 tweet id，而 UI 展示又需要当前 tweet id。

`as_tweet_info` 会把 PostCandidate 转成模型服务需要的 `TweetInfo`，包括原始 tweet、retweeting tweet、quote、reply、视频时长、计数、语言和 bool features。

=== 默认值语义

数据模型里有很多 `Option`，也有一些普通字段默认 0 或空字符串。读代码时要特别注意：

- `author_id=0` 在当前 filter 语境中代表候选缺少有效作者 id，会被当作完整性失败处理。
- `score=None` 在 selector 里是负无穷。
- `visibility_reason=None` 在 VFFilter 中表示不 drop。
- `has_media=None` 在 TweetInfo 中会转成 false。
- `retweeted_tweet_id=None` 表示不是 retweet。

默认值不是实现细节，而是业务语义。

=== 从 Candidate 到 ScoredPost

#codepath("home-mixer/scored_posts_server.rs") 的 `candidates_to_scored_posts` 把内部候选转成响应对象。它会把 Option 转成 proto 默认值：

```rust
score: candidate.score.unwrap_or(0.0) as f32,
in_network: candidate.in_network.unwrap_or(false),
prediction_request_id: candidate.prediction_request_id.unwrap_or(0),
```

这一步是内部语义到外部 API 的边界。内部可以用 Option 表示缺失，响应通常需要具体默认值。

=== 本节练习

1. 给 `PostCandidate` 的字段按 source/hydrator/filter/scorer/response 分类。
2. 找出三个 `Option` 字段，说明 None 在下游代表什么。
3. 解释为什么 retweet 需要 `get_original_tweet_id` 和 `tweet_id` 两套语义。
4. 对比 `PostCandidate` 和 `ScoredPost`，写出哪些字段在响应时被默认化。
