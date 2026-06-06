#import "../style.typ": *

== Thunder 深入，实时关注网络候选

Thunder 是 in-network 候选源。它解决的问题不是“全局找相似内容”，而是“用户关注的人最近发了什么，并且要很快返回”。

=== PostStore 的数据结构

#codepath("thunder/posts/post_store.rs") 中的 `PostStore` 保存几类数据：

```rust
posts: Arc<DashMap<i64, LightPost>>,
original_posts_by_user: Arc<DashMap<i64, VecDeque<TinyPost>>>,
secondary_posts_by_user: Arc<DashMap<i64, VecDeque<TinyPost>>>,
video_posts_by_user: Arc<DashMap<i64, VecDeque<TinyPost>>>,
deleted_posts: Arc<DashMap<i64, bool>>,
```

这里有一个重要设计：完整帖子数据按 `post_id` 存，用户时间线只存 `TinyPost`，也就是 post id 和 created_at。这样按作者查最近内容很快，同时避免在多个队列里重复保存完整帖子。

=== 写入路径

`insert_posts` 会先过滤过旧或来自未来的帖子，再按时间排序，最后调用 `insert_posts_internal`。内部逻辑会：

- 跳过已经删除的帖子。
- 把完整 `LightPost` 写入 `posts`。
- 根据 original/reply/retweet/video 放入不同的 per-user 队列。

这是一种典型的服务端内存索引：写入时多维护几份轻量索引，读取时降低扫描成本。

=== 删除和过期

`mark_as_deleted` 会从 `posts` 移除帖子，并写入 `deleted_posts`。`trim_old_posts` 会定期清理超过 retention 的帖子。

删除和过期都很重要：

- 删除处理保护内容正确性和用户安全。
- 过期清理控制内存大小。
- deleted_posts 还能处理 create/delete 事件乱序。

新手容易只看“如何插入”，但线上系统必须同等重视“如何删除”和“如何收缩”。

=== gRPC 服务层

#codepath("thunder/thunder_service.rs") 暴露 `get_in_network_posts`。它先用 semaphore 限制并发：

```rust
let _permit = match self.request_semaphore.try_acquire() {
    Ok(permit) => permit,
    Err(_) => return Err(Status::resource_exhausted("Server at capacity, please retry")),
};
```

这是一条非常重要的保护线。没有并发限制时，突发流量可能把内存、CPU 或下游服务打满，导致所有请求一起超时。拒绝一部分请求比拖垮整个服务更可控。

=== following list 的来源

Thunder 请求可以直接带 `following_user_ids`。如果请求没带，并且 debug 条件满足，服务会尝试从 Strato 拉取关注列表。线上 Home Mixer 的 ThunderSource 通常会通过 query hydrator 先补关注列表，再传给 Thunder。

这说明同一个数据可以在不同层补：

- Home Mixer 先补，Thunder 只负责查帖子。
- Thunder 自己 fallback 拉取，适合 debug 或特殊场景。

边界越清晰，系统越容易排查。

=== 指标

Thunder 记录了很多指标，例如：

- 请求数和延迟。
- following list 大小。
- exclude list 大小。
- 返回帖子新鲜度。
- reply ratio。
- unique authors。
- posts per author。
- rejected requests。

这些指标回答的问题不是“模型准不准”，而是“实时候选源健康吗”。如果 Thunder 返回的帖子太旧、作者太少、回复比例异常，Home Mixer 后面的排序再好也会受影响。

=== Thunder 和 Phoenix 的互补

Thunder 偏实时、偏关注网络；Phoenix Retrieval 偏全局发现、偏语义相似。一个健康 feed 往往需要二者互补：

- Thunder 保证关注关系和新鲜内容。
- Phoenix 帮用户发现关注网络之外的内容。
- RankingScorer 再统一打分和做 OON 权重调整。

如果用户关注的人很少，Thunder 候选不足；如果 Phoenix 召回质量下降，feed 可能缺少新发现。排查时要分开看 in-network 和 out-of-network 的供给。

=== 本节练习

1. 在 `PostStore` 中画出 `posts`、`original_posts_by_user`、`deleted_posts` 的关系。
2. 解释为什么 per-user 队列只保存 `TinyPost`。
3. 打开 `ThunderServiceImpl::get_in_network_posts`，找出并发保护、输入限制、指标记录三个位置。

