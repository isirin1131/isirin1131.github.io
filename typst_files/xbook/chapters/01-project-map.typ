#import "../style.typ": *

== 先画地图，再读代码

推荐系统的代码不能从模型文件开始读。模型只回答“这个候选内容有多可能触发某些行为”，但系统还要回答“候选内容从哪里来、哪些内容不能展示、哪些副作用要记录、响应里还要混入什么”。所以第一站是项目地图。

=== 一次请求的鸟瞰图

```text
用户打开 For You
    |
    v
home-mixer/server.rs
    |
    v
ForYouCandidatePipeline
    |-- ScoredPostsSource  -> ScoredPostsServer
    |                         |
    |                         v
    |                    PhoenixCandidatePipeline
    |                         |-- ThunderSource
    |                         |-- PhoenixSource / PhoenixTopicsSource / PhoenixMOESource
    |                         |-- TweetMixerSource / CachedPostsSource
    |
    |-- AdsSource
    |-- WhoToFollowSource
    |-- PromptsSource
    |-- PushToHomeSource
    v
BlenderSelector
    |
    v
Feed response
```

这里有两个层次。内层 `PhoenixCandidatePipeline` 主要产出“已打分的帖子候选”。外层 `ForYouCandidatePipeline` 把帖子、广告、关注推荐、提示等 feed item 混合起来，形成最终 feed。

#checkpoint("不要把 Phoenix 等同于整个推荐系统", [
  Phoenix 是模型组件；推荐系统还包括候选源、过滤、缓存、可见性、安全、日志和实验。只懂模型，通常无法解释线上推荐为什么慢、为什么空、为什么某类内容被过滤。
])

=== 代码入口

当前仓库的 README 已经说明 For You 系统由 Home Mixer、Thunder、Phoenix、Candidate Pipeline 组成。本书把这几个入口连起来：

#table(
  columns: (2.1fr, 3.2fr),
  inset: 6pt,
  stroke: 0.5pt + line,
  [入口], [读它时要问的问题],
  [#codepath("candidate-pipeline/candidate_pipeline.rs")], [通用流水线怎样定义阶段？哪些阶段并行？哪些阶段顺序？],
  [#codepath("home-mixer/candidate_pipeline/phoenix_candidate_pipeline.rs")], [For You 的帖子候选实际配置了哪些 hydrator、source、filter、scorer？],
  [#codepath("home-mixer/candidate_pipeline/for_you_candidate_pipeline.rs")], [最终 feed 除了帖子，还混入了哪些业务 item？],
  [#codepath("phoenix/recsys_retrieval_model.py")], [召回模型怎样把用户和候选映射到同一个向量空间？],
  [#codepath("phoenix/recsys_model.py")], [排序模型接收哪些输入？怎样输出多种行为的预测？],
  [#codepath("thunder/posts/post_store.rs")], [近实时帖子如何保存在内存结构里，供 in-network 召回使用？],
  [#codepath("grox/engine.py")], [内容理解任务如何异步调度和执行？],
)

=== 推荐系统里的几种“数据”

新手读代码时，最容易把所有数据都叫“特征”。为了降低混乱，本书先区分五类数据：

#term("Query 数据", [和本次请求、当前用户有关。例如 user id、IP、关注列表、近期行为序列、已经曝光过的内容。])

#term("Candidate 数据", [和某个候选内容有关。例如 post id、作者、文本、媒体、语言、视频时长、是否来自关注网络。])

#term("Model 输入", [被整理成模型能吃的张量、hash、embedding、action 序列、product surface。])

#term("Decision 数据", [模型打分之后，业务层用于过滤、排序、混排、可见性判断的数据。])

#term("Side-effect 数据", [响应之后还要写出去的数据。例如曝光日志、缓存、统计、Kafka 事件。])

这五类数据会在后续章节反复出现。你读一个函数时，先判断它正在处理哪类数据，理解速度会快很多。

=== 为什么项目会分这么多阶段

一个简单推荐 demo 可能只有：

```python
candidates = retrieve(user)
scores = model(user, candidates)
return top_k(candidates, scores)
```

真实系统不能这么写，原因有三点。

第一，候选源很多。关注网络、全局语义召回、主题召回、缓存、广告和运营内容并不来自同一处。

第二，延迟很紧。能并行的外部请求必须并行，否则一次请求会被几十个远程调用串起来拖慢。

第三，失败是常态。某个 hydrator 或候选源失败时，系统经常需要降级，而不是让整个 feed 空掉。

`candidate-pipeline` 的意义就在这里：把“推荐请求的常见骨架”抽出来，让具体业务只配置组件。
