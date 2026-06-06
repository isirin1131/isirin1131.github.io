#import "../style.typ": *

== 学习路线、练习和术语表

这一节把前面内容整理成一套可以执行的学习计划。你可以按周推进，也可以把每一节当成代码阅读 checklist。

=== 七天入门路线

#table(
  columns: (0.7fr, 2.2fr, 3.4fr),
  inset: 6pt,
  stroke: 0.5pt + line,
  [天], [主题], [完成标准],
  [1], [项目地图], [能说出 `candidate-pipeline`、`home-mixer`、`phoenix`、`thunder`、`grox` 各自角色。],
  [2], [流水线阶段], [能不看代码复述 `execute` 的阶段顺序。],
  [3], [并行与顺序], [能解释为什么 source/hydrator 常并行，filter/scorer 常顺序。],
  [4], [Phoenix Retrieval], [能画出 user tower、candidate tower、dot product 检索。],
  [5], [Phoenix Ranking], [能解释 `RecsysBatch`、candidate isolation、多行为预测。],
  [6], [服务化组件], [能解释 Thunder、Grox、side effects 为什么不是“模型细节”但仍影响推荐。],
  [7], [端到端复盘], [从用户打开 feed 到返回结果，完整讲一遍数据流。],
)

=== 代码阅读 checklist

读任何一个组件时，按这个顺序写笔记：

- 组件名是什么？属于 source、hydrator、filter、scorer、selector 还是 side effect？
- 输入类型是什么？只读 query，还是会读 candidates？
- 输出写到哪里？更新 query、更新 candidate、返回 removed、写外部系统？
- 它是否 async？如果 async，等待的是模型服务、存储、Kafka、RPC，还是后台任务？
- 失败时发生什么？返回空、默认值、错误，还是跳过？
- 它对用户体验的影响是什么？相关性、安全、延迟、多样性、去重、商业化、观测性？

=== 推荐算法术语表

#term("Candidate", [候选内容。进入排序前，它只是“可能展示”的对象，不代表最终会展示。])

#term("Query Hydrator", [补齐本次请求上下文的组件，例如用户历史、关注列表、屏蔽列表。])

#term("Candidate Hydrator", [补齐候选内容信息的组件，例如 core data、作者资料、媒体、语言、安全标签。])

#term("Source", [产生候选的组件。一个 source 可能来自实时内存库、向量召回、缓存、广告系统或其他服务。])

#term("Filter", [删除不合格候选的组件。过滤不只是安全，也包括去重、年龄、可见性、订阅资格、已曝光等。])

#term("Scorer", [给候选写入分数或排序信号的组件。模型调用和加权组合都可以是 scorer。])

#term("Selector", [从打分后的候选里选择最终返回的一批，可能包含排序、截断、混排和多样性规则。])

#term("Side effect", [不直接改变当前返回内容，但会写日志、缓存、统计或实验数据的操作。])

#term("Retrieval", [召回。目标是从大规模候选中快速找出一批可能相关的内容。])

#term("Ranking", [排序。目标是对召回后的较小候选集做更精细的预测和排序。])

#term("Embedding", [把离散对象或行为表示成向量，让模型能计算相似度或进行神经网络运算。])

#term("Candidate isolation", [排序 transformer 中候选不能互相 attention，只能看用户、历史和自己。])

#term("Backfill / degradation", [某个依赖失败时，用缓存、默认值或较弱策略继续服务，避免整个请求失败。])

=== 三个进阶项目

1. 给 `PhoenixCandidatePipeline` 画一张真实组件图。把 query hydrator、source、hydrator、filter、scorer、side effect 全部列出来，并标记哪些可能访问外部服务。
2. 写一个最小候选流水线伪代码。只实现两个 source、两个 filter、一个 scorer、一个 selector，用数组模拟候选流动。
3. 对 Phoenix 排序输出做一次手算。假设某候选 `favorite=0.2`、`reply=0.03`、`not_interested=0.01`，给定三个权重，算出加权分，并解释负反馈为什么要进入公式。

=== 继续扩写本书的方向

这版书稿先建立“能读懂项目”的主线。后续可以继续补：

- 逐文件导读：每章带读一个真实 source、filter、hydrator、scorer。
- 实验系统：feature switch、decider、参数权重、A/B 分析。
- 可观测性：tracing span、stats receiver、空结果率、延迟分桶。
- 数据闭环：曝光日志、用户行为、训练样本、模型更新。
- 本地实验：使用 `phoenix/run_pipeline.py` 跑一次 retrieval -> ranking demo。

#checkpoint("真正的掌握标准", [
  不是能背出所有组件名，而是能拿到任意一个新组件，判断它处在流水线哪一段、依赖什么数据、失败会影响什么、怎样验证它是否按预期工作。
])
