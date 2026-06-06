#import "../style.typ": *

== 从模型到服务，推荐系统怎样活在线上

前几章讲的是“候选帖子怎样被召回和排序”。这一节把视角拉回线上服务：一次 feed 请求不只返回帖子，也不只调用一个模型。

=== 外层 For You 流水线

#codepath("home-mixer/candidate_pipeline/for_you_candidate_pipeline.rs") 配置的是最终 feed item 的混排。它的 source 包括：

- `ScoredPostsSource`：来自内层帖子打分服务。
- `AdsSource`：广告。
- `WhoToFollowSource`：关注推荐。
- `PromptsSource`：提示或运营类内容。
- `PushToHomeSource`：推送到 Home 的内容。

然后它用 `BlenderSelector` 做混排，并在 side effects 中记录广告注入、曝光、客户端事件、served history 等。

#beginner("内层和外层的区别", [
  内层 `PhoenixCandidatePipeline` 更像“帖子推荐算法”；外层 `ForYouCandidatePipeline` 更像“feed 产品编排”。线上用户看到的是外层结果。
])

这就是为什么推荐算法工程师不能只看模型输出。模型给出的是候选帖子的排序信号；产品响应还要处理广告、关注推荐、历史去重、日志和缓存。

=== Thunder：实时 in-network 候选

Thunder 负责“你关注的人最近发了什么”。在 #codepath("thunder/posts/post_store.rs") 中，`PostStore` 用多个 `DashMap` 保存帖子：

```rust
posts: Arc<DashMap<i64, LightPost>>,
original_posts_by_user: Arc<DashMap<i64, VecDeque<TinyPost>>>,
secondary_posts_by_user: Arc<DashMap<i64, VecDeque<TinyPost>>>,
video_posts_by_user: Arc<DashMap<i64, VecDeque<TinyPost>>>,
deleted_posts: Arc<DashMap<i64, bool>>,
```

这个结构体现了两个线上需求：

- 查某个作者最近内容要快，所以按 user id 组织队列。
- 删除和过期要及时处理，所以有 deleted map 和 retention trim。

`start_auto_trim` 会后台定期清理旧帖子。`start_stats_logger` 会定期记录用户数、帖子数、删除数等指标。这些看起来不是算法，却决定了召回源是否健康。

#tip("后台任务也是系统能力", [
  `interval.tick().await` 这行代码表达的是周期性调度，而不是用户请求路径。后台清理和指标上报看起来离算法远，但它们决定实时候选源能否长期保持健康。
])

=== Grox：内容理解不是排序，但会影响推荐

#codepath("grox/") 不是主排序流水线，但它代表内容理解任务：分类、摘要、多模态 embedding、安全策略等。#codepath("grox/engine.py") 里的 `Engine` 会从队列取任务，然后异步执行：

```python
task = await self._poll_task()
if task is None:
    await asyncio.sleep(0.1)
    continue
asyncio.create_task(self._run_task(task))
```

这说明内容理解通常不是“请求来了才全部现算”。很多结果会提前写入存储，供推荐侧 hydration、filter 或模型输入使用。

对新手来说，先记住一句话：推荐系统不只需要知道“用户喜欢什么”，还需要知道“内容是什么、是否安全、是否可展示、是否适合这个场景”。

=== Side effects：响应之后还要做的事

在 `CandidatePipeline::execute` 的最后，系统调用 `run_side_effects(input)`。实现里用 `tokio::spawn` 把 side effects 放到后台任务里：

```rust
tokio::spawn(async move {
    let futures = side_effects
        .iter()
        .filter(|se| se.enable(input.query.clone()))
        .map(|se| se.run(input.clone()));
    let _ = join_all(futures).await;
});
```

side effect 的例子包括：

- 写曝光和候选日志到 Kafka。
- 更新 served history，避免短时间重复展示。
- 写 Redis 缓存，给后续请求复用。
- 记录统计指标，帮助发现空结果、延迟和异常。
- 触发实验相关数据收集。

这些操作重要，但很多不应该阻塞用户响应。否则用户看到 feed 的时间会被日志系统、缓存系统或统计系统拖慢。

#caution("后台不代表不重要", [
  side effect 失败可能不会让当前请求失败，但会影响后续推荐质量、实验分析和问题排查。线上系统需要指标、重试、降级和告警来管理这些失败。
])

=== 新手需要的服务化系统最小模型

先不要背复杂术语。读这个项目时，只需要带着下面五个问题：

1. 这个组件依赖什么外部资源？
2. 这个依赖可以和其他工作并行吗？如果不能，依赖是什么？
3. 失败时是丢弃部分结果、使用默认值，还是让整个请求失败？
4. 这个结果会不会被缓存？缓存过期或不一致会怎样？
5. 这个阶段影响当前响应，还是影响后续请求和分析？

这五个问题足够支撑你读懂多数服务化推荐代码。

=== 本节练习

1. 在 #codepath("home-mixer/candidate_pipeline/for_you_candidate_pipeline.rs") 里找到所有 source，判断哪些是帖子，哪些不是帖子。
2. 在 #codepath("thunder/posts/post_store.rs") 里找出删除、过期清理和统计上报对应的方法。
3. 在 #codepath("grox/engine.py") 中解释 `asyncio.create_task` 和直接等待任务完成的区别。
