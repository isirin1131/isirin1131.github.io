#import "../style.typ": *

== CandidatePipeline，推荐请求的主干

这一节只盯一个文件：#codepath("candidate-pipeline/candidate_pipeline.rs")。它是本项目最适合新手入门的地方，因为它把推荐请求拆成了清楚的阶段。

=== `execute` 是整条路的目录

`CandidatePipeline::execute` 的主流程可以直接搜索 `async fn execute` 定位。简化后是这样：

```rust
async fn execute(&self, query: Q) -> PipelineResult<Q, C> {
    let hydrated_query = self.hydrate_query(query).await;
    let hydrated_query = self.hydrate_dependent_query(hydrated_query).await;

    let candidates = self.fetch_candidates(&hydrated_query).await;
    let hydrated_candidates = self.hydrate(&hydrated_query, candidates).await;

    let (kept_candidates, mut filtered_candidates) =
        self.filter(&hydrated_query, hydrated_candidates.clone());

    let scored_candidates = self.score(&hydrated_query, kept_candidates).await;
    let selected_candidates = self.select(&hydrated_query, scored_candidates);

    let post_selection_hydrated_candidates =
        self.hydrate_post_selection(&hydrated_query, selected_candidates).await;

    let (mut final_candidates, post_selection_filtered_candidates) =
        self.filter_post_selection(&hydrated_query, post_selection_hydrated_candidates);

    self.run_side_effects(input);
    PipelineResult { ... }
}
```

这个函数的价值不是语法，而是顺序。推荐系统把一次请求拆成：

#table(
  columns: (1.3fr, 2.4fr, 2.6fr),
  inset: 6pt,
  stroke: 0.5pt + line,
  [阶段], [输入和输出], [新手理解],
  [Query hydration], [query -> 更完整的 query], [先补用户上下文。没有上下文，后面不知道该召回什么。],
  [Source], [query -> candidates], [从多个地方拿候选内容。],
  [Candidate hydration], [candidates -> 更完整的 candidates], [补内容元信息，例如作者、媒体、语言、安全标签。],
  [Filter], [candidates -> kept + removed], [先删掉明显不能展示的内容，减少后续模型成本。],
  [Score], [candidates -> scored candidates], [调用模型或规则，得到排序分数。],
  [Selector], [scored candidates -> selected + rest], [排序、截断、混排。],
  [Post-selection], [selected -> final], [最终可见性检查和响应前补充。],
  [Side effect], [final + rest -> 异步写日志/缓存], [返回响应不一定要等所有写入完成。],
)

#beginner("先看阶段，不急着看泛型", [
  `Q` 可以先理解成 query 类型，`C` 可以先理解成 candidate 类型。trait、泛型和 boxed dyn 是为了让同一个流水线框架服务不同业务；第一次读时，不需要把 Rust 类型系统全部展开。
])

=== 哪些地方并行

你会在这个文件里反复看到 `join_all`。它的意思是：把一组异步任务同时发出去，然后等它们都返回。

例如 `hydrate_query` 会筛选启用的 query hydrator，然后把每个 hydrator 的 `run` 变成 future：

```rust
let hydrate_futures = hydrators.iter().map(|h| h.run(&query));
let results = join_all(hydrate_futures).await;
```

`fetch_candidates` 对 source 做同样的事：

```rust
let source_futures = sources.iter().map(|s| s.run(query));
let results = join_all(source_futures).await;
```

这里要带走的重点是阶段依赖：query hydrator 和 source 可以 fan-out 并行，filter 和 scorer 通常按顺序收敛。异步语法只是实现手段，真正影响系统行为的是依赖关系、候选数量和失败策略。

#tip("判断能否并行的标准", [
  如果组件之间只读同一份 query，彼此不依赖，就适合并行。例如多个 source 同时取候选。若后一个组件必须基于前一个组件的输出，就必须顺序。例如 filter 会逐个缩小候选集。
])

=== 哪些地方顺序

过滤器是顺序执行的。`run_filters` 会把候选列表交给第一个 filter，拿到 kept 和 removed；再把 kept 交给下一个 filter。核心结构是：

```rust
for filter in filters.iter().filter(|f| f.enable(query)) {
    let result = filter.run(query, candidates);
    candidates = result.kept;
    all_removed.extend(result.removed);
}
```

为什么不并行？因为过滤器之间会改变候选集合。去重之后，年龄过滤面对的输入已经变少；可见性过滤可能依赖 hydration 结果。如果并行跑所有过滤器，就要处理“同一个候选被多个过滤器同时移除”的归因问题，也很难记录每个过滤器到底删了多少。

scorer 也是顺序执行的。`score` 会依次运行启用的 scorer，并把结果更新回 candidates：

```rust
for scorer in all.iter().filter(|s| s.enable(query)) {
    let scored = scorer.run(query, &candidates).await;
    scorer.update_all(&mut candidates, scored);
}
```

这说明 scorer 不一定只有模型。一个 scorer 可以写入 Phoenix 的预测；另一个 scorer 可以把多种预测加权成一个最终分；再一个 scorer 可以做作者多样性衰减。

=== Home Mixer 怎样配置这条流水线

抽象框架本身不决定业务。真正的业务配置在 #codepath("home-mixer/candidate_pipeline/phoenix_candidate_pipeline.rs")。

在 `build_with_clients` 里，帖子候选流水线配置了：

- query hydrators：补 scoring sequence、retrieval sequence、关注列表、屏蔽列表、IP、话题、订阅关系等。
- sources：`ThunderSource`、`TweetMixerSource`、`PhoenixSource`、`PhoenixTopicsSource`、`PhoenixMOESource`、`CachedPostsSource`。
- hydrators：补 in-network 标记、core data、quote、视频时长、媒体、订阅、作者资料、语言等。
- filters：去重、年龄、自发帖、转帖去重、订阅资格、已看、已服务、静音关键词、社交图关系、视频、话题等。
- scorers：`PhoenixScorer`、`RankingScorer`、`VMRanker`。
- post-selection hydrators 和 filters：可见性、安全、广告 brand safety、会话去重等。
- side effects：实验、Kafka、Redis 缓存、统计、请求缓存等。

这份配置是读推荐系统的宝藏：它告诉你线上 feed 并不只是“拿候选、模型打分、top k”。真正的系统要在算法效果、产品规则、安全合规和工程延迟之间折中。

=== 本节练习

1. 打开 #codepath("candidate-pipeline/candidate_pipeline.rs")，只读 `execute`，手写一遍阶段名。
2. 在 `hydrate_query`、`fetch_candidates`、`run_hydrators` 中找出 `join_all`，写下它们并行的对象分别是什么。
3. 在 #codepath("home-mixer/candidate_pipeline/phoenix_candidate_pipeline.rs") 中数一数 `sources` 有几个；想一想如果其中一个 source 失败，系统为什么不应该直接让整个 feed 失败。
