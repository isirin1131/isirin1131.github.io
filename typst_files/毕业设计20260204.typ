/*
 * Template for APS PRAB styled papers
 *
 * This file is part of the revtyp template.
 * Typst universe: https://typst.app/universe/package/revtyp
 * GitHub repository: https://github.com/eltos/revtyp
 */

#import "@preview/revtyp:0.14.0": revtable, revtyp

#show: revtyp.with(
  journal: "PRAB",

  // Paper title
  title: [
    FlowCabal 技术报告
  ],

  // Author list
  authors: (
    (name: "田照涛. Author", at: "gzqy", email: "isirin1131@outlook.com", orcid: "0009-0002-4673-9698"),
    (name: "杨森. CoAuthor", at: "ys", email: "billhoyou@163.com", orcid:"0009-0008-1575-5269"),
  ),
  affiliations: (
    gzqy: [#link("https://www.gzqy.cn")[贵州轻工职业大学], 贵州, 中国],
    ys: [#link("https://www.lngpi.edu.cn/")[辽宁轨道交通职业学院], 辽宁, 中国]
  ),
  group-by-affiliation: true,

  // Paper abstract
  abstract: [
    FlowCabal 是一款专注于 AI 辅助写作的软件，专门面向高质量长篇写作的场景。软件提供蓝图式工作流编排、高级查询函数、多种工作流控件、内置 agent 助手和官方 agent skill。本文将从产品愿景、关键功能、技术选型、软件架构、交互设计和具体用例等方面介绍这款软件。软件源代码在 #link("https://github.com/isirin1131/FlowCabal")[Github] 开源
  ],

  // Other optional information
  date: [(Drafted #datetime.today().display("[day] [month repr:long] [year]");)],
  // doi: "https://doi.org/10.1103/PhysRevAccelBeams.00.000000",
  header: (
    //title: [PHYSICAL REVIEW ACCELERATORS AND BEAMS *00*, 000000 (0000)],
    left: (even: none, odd: none),
    right: (even: none, odd: none),
  ),
  footer: (
    title-left: none,
    title-right: none,
    center: [
      page #context counter(page).display()
      of #context counter(page).final().last()
    ],
  ),
  footnote-text: [
    
  ],
  //wide-footnotes: true,

  // Writing utilities
  //show-line-numbers: true,
)

#set text(
  // 英文优先使用 New Computer Modern (学术巅峰)
  // 中文自动回退到 Source Han Serif SC (现代正式)
  font: ("New Computer Modern", "Source Han Serif SC"),
  lang: "zh"
)

// 代码块美化：使用更纱黑体或 JetBrains Mono
#show raw: set text(font: ("JetBrains Mono", "Sarasa Fixed Slab SC"), size: 7.5pt)

// 2. 背景与间距美化
#show raw.where(block: true): it => block(
  fill: rgb("#f2eef7"),      // 背景颜色：浅紫色
  inset: 5pt,                // 内边距：避免文字顶着边缘
  width: 100%,               // 宽度：占满整行
  it                         // 渲染代码本身
)

#import "@preview/physica:0.9.7": *
#import "@preview/zero:0.5.0"
#import "@preview/lilaq:0.5.0" as lq
#import "@preview/glossy:0.7.0"

#show: glossy.init-glossary.with((

))



= 引言

受限于如今的模型性能，AI 辅助写作很难找到一站式的解决方案，为此，FlowCabal 希望提供一种高度定制化且足够现代的范式来回答这个问题。

当以 ChatGPT 为首的，基于 LLM 的 chat-ai-app 刚刚进入人们视野的时候，第一个被广泛关注的概念是*提示词工程*#footnote[reddit 的 PromptEngineering 板块创建于 2021年2月26日]；而在 2025 年初到 2026 年初的 AI 编程大爆发和 agent 大爆发中#footnote[Anthropic 于 2024年11月25日开源了他们的 MCP 协议，可以看作是 agent 时代开始的里程碑事件]，另一个在幕后扮演重要角色的概念是*上下文工程*。这两个概念几乎涵盖了当下 LLM 应用的所有注意事项，而对于 AI 辅助写作这个领域，FlowCabal 提供的范式同样围绕这两个概念展开。

= 关键功能

本节以渐进式的视角审视了 FlowCabal 的功能设计，省略了很多软件实现上的细节，力求以更通用的视角解释清楚 FlowCabal 的原理和优点。

== 节点工作流 <sec:node>

假如将 LLM 抽象为 `Model(query) = Answer`，那么常见的 chat-ai-app 多是以如下的形式组织 `query` 的：

```json
"query": [
    { "role": "user", "content": "你好" },
    { "role": "assistant", "content": "你好！有什么我可以帮助你的吗？" },
    { "role": "user", "content": "你是谁" },
  ......
]
```

而节点工作流则是这种形式的超集，Unreal Engine 的蓝图、ComfyUI 或是如今已经成为 agent 领域经典实践的 LangGraph 都采用了这种组织方式。

FlowCabal 的一个节点工作流可以描述为 `[Model]_n`，其中 `Model_k.query = fuc_k(m.Answer | m in M_k)`，`M_k` 是 `[Model]_n` 的一个子集，`fuc_k` 是自定义函数，比如 `[fuc_add(a, b, c) -> a + "+" + b + "+" + c]["1", "2", "3"] = "1+2+3"`。

这样的工作流一般来说会有满足 DAG 形式的依赖关系，使用 Kahn 算法排序后即可逐个解析，如果有环状依赖出现，在工程上则可以设置停机收敛条件。

FlowCabal 还提供了不少有趣且实用的功能，这些功能使 FlowCabal  成为节点式工作节点式工作流的超集。在 @sec:advfuc 和 @sec:agent 中有进一步的描述。

另一个值得一提的现象是节点工作流的调用方式天然带有上下文压缩的色彩，`M_k.query` 完全不会出现在其余任何 `M_p.query` 中。@sec:contxt 详细介绍了 FlowCabal 的上下文策略。

== 高级查询函数与高级功能 <sec:advfuc>

有非常多的研究如 RSA@venkatraman2025recursiveselfaggregationunlocksdeep 和 RLM@zhang2026recursivelanguagemodels 表明，递归和复杂迭代可以作为 LLM 推理的强力可选项，这些推理过程显然是 @sec:node 中提到的节点工作流无法涵盖的。FlowCabal 提供了一组高级查询函数 `[adv_fuc]_n`，可以在工作流中使用。

由于 LLM 的不稳定性，工作流的每个节点 `Model_k` 可能都会有多次重试，所以 FlowCabal 会默认保留每个节点的 `Model_k.Answer` 的历史记录，并提供 “冻结” 功能使一个节点在本次工作流运行中永不重试。基于这两点设计，一个 FlowCabal 工作流的运行依然按照 Kahn 序一个一个解析节点——只是对人类介入的需求过于高了。

另一个值得一提的设计是子流程，假如工作流的运行只有人类来介入，这个设计的价值将大打折扣。请看 @sec:agent。

== Agent 赋能 <sec:agent>

FlowCabal 的 agent 功能不只是用于编写工作流，还用于监控工作流的运行。这样的 agent 几乎必定需要在整个小说内探索需要的上下文，也因此必然需要引入成熟的上下文管理器从而一站式解决长短期记忆问题。FlowCabal 的选型是字节跳动开源的 OpenViking#footnote[https://github.com/volcengine/OpenViking]，其基于虚拟文件系统带来的检索可追踪性和多级摘要的上下文披露无疑是 FlowCabal 所需要的，OpenViking 还内置递归式的上下文检索，这也与 @sec:advfuc 的主张有所呼应。



== 摘要与上下文艺术 <sec:contxt>

“上下文腐化”@hong2025context 








// #figure(
//   placement: bottom, // `top`, `bottom` or `auto` for floating placement or `none` for inline placement
//   rect(width: 100%, height: 5cm, fill: gradient.linear(
//     ..color.map.crest,
//     angle: 140deg,
//   )),
//   caption: [
//     A placeholder figure with a linear gradient @TheLawOfLeakyAbs
//   ],
// ) <fig:example>



= 技术选型

= 软件架构



// #figure(
//   scope: "parent", // two column-figure
//   placement: top, // `top`, `bottom` or `auto`
//   box(
//     fill: gradient.linear(..color.map.flare, angle: 120deg),
//     width: 100%,
//     height: 2cm,
//   ),
//   caption: [
//     A column spanning figure. 
//   ],
// ) <fig:rect>


= 前端交互设计


// See the import section near the top of this document


= 用例和效果评估













= 总结



#show heading: set heading(numbering: none)

= 致谢

感谢我的家人、老师和朋友


#bibliography("ref.bib")



// Workaround until balanced columns are available
// See https://github.com/typst/typst/issues/466
#place(
  bottom,
  scope: "parent",
  float: true,
  clearance: 0pt, // TODO: increase clearance for manual column balancing
  [],
)



