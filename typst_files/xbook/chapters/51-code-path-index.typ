#import "../style.typ": *

== 代码路径索引

这是本书常用代码路径的速查索引。遇到问题时，可以从这里跳到对应文件。

=== 框架层

#table(
  columns: (2.2fr, 3fr),
  inset: 5pt,
  stroke: 0.5pt + line,
  [路径], [用途],
  [#codepath("candidate-pipeline/candidate_pipeline.rs")], [pipeline 主执行流程。],
  [#codepath("candidate-pipeline/query_hydrator.rs")], [query hydrator 合约。],
  [#codepath("candidate-pipeline/source.rs")], [source 合约。],
  [#codepath("candidate-pipeline/hydrator.rs")], [hydrator 和 cached hydrator 合约。],
  [#codepath("candidate-pipeline/filter.rs")], [filter 合约。],
  [#codepath("candidate-pipeline/scorer.rs")], [scorer 合约。],
  [#codepath("candidate-pipeline/selector.rs")], [selector 合约。],
  [#codepath("candidate-pipeline/side_effect.rs")], [side effect 合约。],
)

=== Home Mixer

#table(
  columns: (2.2fr, 3fr),
  inset: 5pt,
  stroke: 0.5pt + line,
  [路径], [用途],
  [#codepath("home-mixer/server.rs")], [gRPC 入口和 QueryBuilder。],
  [#codepath("home-mixer/scored_posts_server.rs")], [帖子候选 pipeline 运行和响应转换。],
  [#codepath("home-mixer/candidate_pipeline/phoenix_candidate_pipeline.rs")], [内层帖子候选 pipeline 配置。],
  [#codepath("home-mixer/candidate_pipeline/for_you_candidate_pipeline.rs")], [外层 feed item pipeline 配置。],
  [#codepath("home-mixer/models/query.rs")], [ScoredPostsQuery 数据模型。],
  [#codepath("home-mixer/models/candidate.rs")], [PostCandidate 数据模型。],
)

=== Phoenix

#table(
  columns: (2.2fr, 3fr),
  inset: 5pt,
  stroke: 0.5pt + line,
  [路径], [用途],
  [#codepath("phoenix/recsys_retrieval_model.py")], [two-tower retrieval model。],
  [#codepath("phoenix/recsys_model.py")], [ranking model。],
  [#codepath("phoenix/grok.py")], [Transformer 和 recommendation attention mask。],
  [#codepath("phoenix/run_pipeline.py")], [本地 retrieval + ranking demo。],
  [#codepath("phoenix/runners.py")], [模型参数和 runner 工具。],
  [#codepath("phoenix/test_recsys_model.py")], [ranking mask 和位置测试。],
  [#codepath("phoenix/test_recsys_retrieval_model.py")], [retrieval model 测试。],
)

=== Thunder 和 Grox

#table(
  columns: (2.2fr, 3fr),
  inset: 5pt,
  stroke: 0.5pt + line,
  [路径], [用途],
  [#codepath("thunder/posts/post_store.rs")], [实时帖子内存索引。],
  [#codepath("thunder/thunder_service.rs")], [in-network gRPC 服务。],
  [#codepath("thunder/kafka/")], [Kafka ingestion 相关。],
  [#codepath("grox/engine.py")], [内容理解任务执行入口。],
  [#codepath("grox/plans/plan_master.py")], [多 plan 并行执行和合并。],
  [#codepath("grox/plans/plan.py")], [有依赖的任务图执行。],
)

=== 使用方式

遇到 bug 时，先判断阶段，再去索引找入口文件。不要从全局搜索结果随便跳，因为推荐系统同名概念很多。

