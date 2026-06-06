#import "style.typ": *

#set document(
  title: "读懂 x-algorithm：推荐系统工程导读",
  author: "x-algorithm 教程书",
)
#set page(
  paper: "a4",
  margin: (x: 2.15cm, y: 2.35cm),
  numbering: "1",
  number-align: center,
)
#set text(
  font: ("PingFang SC", "Hiragino Sans GB", "Arial Unicode MS", "New Computer Modern"),
  lang: "zh",
  region: "cn",
  size: 10.5pt,
  fill: ink,
)
#set par(justify: true, leading: 0.68em, first-line-indent: 1.5em)
#set heading(numbering: "1.1")
#show raw: set text(font: ("Hack Nerd Font Mono", "Menlo", "Courier New"), size: 8.6pt)
#show link: underline

#align(center)[
  #v(3.2cm)
  #text(size: 27pt, weight: "bold")[读懂 x-algorithm]
  #v(0.45cm)
  #text(size: 15pt, fill: muted)[推荐系统工程导读]
  #v(1.1cm)
  #text(size: 11pt)[沿着真实项目讲清推荐系统、算法模型、异步服务和分布式工程]
  #v(1.2cm)
  #text(size: 9pt, fill: muted)[Typst 源码入口：`docs/recsys-beginner-book/main.typ`]
]

#pagebreak()

#outline(title: [目录], indent: auto)

#pagebreak()

= 前言：读这本书的路线

这本书现在按“从一次 For You 请求读完整个 x-algorithm 项目”的顺序组织。每个一级章回答一个稳定问题：这一层为什么存在、吃什么输入、产出什么结果、依赖哪些服务和模型、失败后怎样降级。分布式、异步和算法知识都放回具体代码场景里讲，服务于读懂项目，而不是抢走主线。

#include "chapters/00-preface.typ"

#pagebreak()

= 读代码前的地图

本章先建立全局坐标。新手读推荐系统最容易在模型、服务、缓存和实验之间来回跳；所以开头只做两件事：看清项目分层，并把后续学习路线放回这张地图。

#include "chapters/01-project-map.typ"
#include "chapters/06-study-plan.typ"

#pagebreak()

= Candidate Pipeline：请求主干和阶段边界

学完地图之后，主线进入框架层。这里的重点不是 Rust 语法，也不是某个异步关键字，而是一次推荐请求如何被拆成可并行、可顺序、可观测、可降级的阶段。理解这一章，后面所有 source、hydrator、filter、scorer 都会有位置。

#include "chapters/06-async-distributed.typ"
#include "chapters/02-candidate-pipeline.typ"
#include "chapters/34-request-lifecycle.typ"
#include "chapters/33-data-models.typ"

#pagebreak()

= Phoenix：从召回到精排

有了流水线骨架，下一步看模型在系统里具体提供什么能力。Phoenix 不是整套推荐系统本身，它负责把用户历史和候选内容变成召回向量、行为预测和可排序信号。

#include "chapters/03-phoenix-retrieval.typ"
#include "chapters/04-phoenix-ranking.typ"
#include "chapters/15-phoenix-hands-on.typ"
#include "chapters/35-phoenix-internals.typ"
#include "chapters/36-retrieval-ranking-labs.typ"

#pagebreak()

= Home Mixer：把算法变成产品响应

这一章把模型能力接回线上服务。Home Mixer 的关键价值是编排：它把帖子候选、非帖子模块、广告、安全规则和 side effect 放进一次 For You 响应。

#include "chapters/05-serving-system.typ"
#include "chapters/14-component-catalog.typ"
#include "chapters/07-query-hydration.typ"
#include "chapters/08-sources.typ"
#include "chapters/09-candidate-hydration.typ"

#pagebreak()

= 从候选到最终顺序

候选被召回和补全后，系统还不能直接展示。它必须先删除不该出现的内容，再把预测变成业务分数，最后按产品约束选出可返回的序列。

#include "chapters/10-filtering.typ"
#include "chapters/11-scoring-selection.typ"
#include "chapters/12-side-effects-observability.typ"
#include "chapters/27-selector-blending-deep-dive.typ"

#pagebreak()

= 组件深读：逐文件形成证据链

前面建立了阶段顺序，本章开始逐文件深读。每一节都按同一套问题走：谁启用它、依赖哪些字段、修改哪些字段、失败时保留什么证据。

#include "chapters/22-source-deep-dives.typ"
#include "chapters/23-query-field-tracing.typ"
#include "chapters/24-hydrator-cache-deep-dive.typ"
#include "chapters/25-filter-deep-dives.typ"
#include "chapters/26-scoring-deep-dive.typ"

#pagebreak()

= 状态、内容理解和安全边界

推荐系统不是无状态函数。实时关注网络、内容理解、缓存、served history、可见性和广告安全都会改变候选能否进入最终 feed。本章把这些“模型之外但决定体验”的能力串起来。

#include "chapters/16-thunder-deep-dive.typ"
#include "chapters/17-grox-deep-dive.typ"
#include "chapters/28-cache-state-deep-dive.typ"
#include "chapters/29-visibility-safety.typ"
#include "chapters/37-ads-blending-safety.typ"
#include "chapters/38-thunder-ingestion.typ"

#pagebreak()

= 数据闭环、参数和实验

当一次请求返回后，系统并没有结束。曝光、点击、负反馈、缓存写入和实验分桶会回到下一次请求、离线评估和后续模型。这里讨论“系统如何变化”，而不是只讨论一次调用如何成功。

#include "chapters/19-data-feedback-loop.typ"
#include "chapters/20-params-experiments.typ"
#include "chapters/30-training-evaluation.typ"
#include "chapters/43-parameter-playbook.typ"

#pagebreak()

= 生产工程：排查、观测、测试和降级

理解推荐系统，最终要能解释线上现象。本章把前面的阶段模型落到 runbook、dashboard、测试策略和降级决策上，帮助读者从“看懂代码”走向“能判断系统是否健康”。

#include "chapters/18-production-runbooks.typ"
#include "chapters/31-observability-dashboard.typ"
#include "chapters/39-testing-strategy.typ"
#include "chapters/42-error-degradation.typ"
#include "chapters/52-production-readiness.typ"

#pagebreak()

= 实战工作坊

前面的章节已经给出读法，本章把读法变成练习。每个练习都要求从代码和指标推导，而不是凭经验猜测。

#include "chapters/13-reading-workshop.typ"
#include "chapters/21-mini-pipeline-lab.typ"
#include "chapters/32-capstone-project.typ"
#include "chapters/44-workbook.typ"
#include "chapters/50-debug-scenario-bank.typ"

#pagebreak()

= 新手读码工具箱

最后一章收束为通用能力：怎样读 Rust trait、怎样读 Python/JAX 模型、怎样识别常见误区，以及哪些设计模式值得保留。

#include "chapters/40-rust-patterns.typ"
#include "chapters/41-python-jax-patterns.typ"
#include "chapters/45-extended-glossary.typ"
#include "chapters/47-role-based-reading.typ"
#include "chapters/48-common-mistakes.typ"
#include "chapters/53-design-patterns.typ"
#include "chapters/54-anti-patterns.typ"

#pagebreak()

= 附录 A：代码索引和审校清单

附录不再承载主叙事，而是用于回查和维护。读者完成正文后，可以用这里的索引、审校清单和维护指南检查自己的理解。

#include "chapters/51-code-path-index.typ"
#include "chapters/49-final-audit-checklist.typ"
#include "chapters/46-maintenance-guide.typ"
#include "chapters/57-roadmap.typ"

#pagebreak()

= 附录 B：复习题

#include "chapters/55-review-questions.typ"

#pagebreak()

= 附录 C：习题参考解答

#include "chapters/56-worksheet-answers.typ"
