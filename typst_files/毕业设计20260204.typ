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
    FlowWrite 架构简述与技术报告
  ],

  // Author list
  authors: (
    (name: "田照涛. Author", at: "gzqy", email: "isirin1131@outlook.com", orcid: "0009-0002-4673-9698"),
  ),
  affiliations: (
    gzqy: [#link("https://www.gzqy.cn")[贵州轻工职业大学], 贵州, 中国],
  ),
  group-by-affiliation: true,

  // Paper abstract
  abstract: [
    FlowWrite 是一款专注于 AI 辅助写作的软件，专门面向高质量长篇写作的场景。软件提供蓝图式工作流编排和多种工作流控件（环状运行、冻结等）、外部 Restful API 接口、内置 agent 和官方 agent skill。本文将从产品愿景、技术选型、交互设计、软件架构和具体用例等方面介绍这款软件。软件源代码在 Github 开源 #link("https://github.com/isirin1131/FlowWrite")[FlowWrite]
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
#show raw: set text(font: ("JetBrains Mono", "Sarasa Fixed Slab SC"))

#import "@preview/physica:0.9.7": *
#import "@preview/zero:0.5.0"
#import "@preview/lilaq:0.5.0" as lq
#import "@preview/glossy:0.7.0"

#show: glossy.init-glossary.with((
  APS: "American Physical Society",
  PRAB: "Physical Review Accelerators and Beams",
  RF: "radio frequency",
))



= 引言

受限于如今的模型性能，AI 辅助写作很难找到一站式的解决方案，为此，我希望提供一种高度定制化且足够现代的范式来回答这个问题。

当以 chatgpt 为首的，基于 LLM 的 chat-ai-app 刚刚进入人们视野的时候，第一个被广泛关注的概念是*提示词工程*#footnote[reddit 的 PromptEngineering 板块创建于 2021年2月26日]，而在 2025 年初到 2026 年初的 AI 编程大爆发和 agent 大爆发中#footnote[Anthropic 于 2024年11月25日开源了他们的 MCP 协议，可以看作是 agent 时代开始的里程碑事件]，另一个在幕后扮演重要角色的概念是*上下文工程*。这两个概念几乎涵盖了当下 LLM 应用的所有注意事项，而对于 AI 辅助写作这个领域，FlowWrite 提供的范式同样围绕这两个概念展开。

@zhang2026recursivelanguagemodels



== 问题

众所周知，今天主流 LLM 的上下文窗口十分有限，即使有足够的窗口长度，模型的注意力也有限。截至 2026 年 2 月，我们依然不能说所谓“上下文腐化”@hong2025context 的现象已经不存在了，作为侧面的佐证，上下文管理器仍然是各 AI 编程工具的重要组件。



```ts
class FlowWriteDB extends Dexie {
  workflows!: Table<WorkflowRecord>;
  settings!: Table<SettingsRecord>;

  constructor() {
    super('FlowWriteDB');

    this.version(1).stores({
      workflows: 'id, name, updatedAt',
      settings: 'key'
    });
  }
}
```

This is a template for submission of manuscripts to @PRAB // abbreviation
using the great, modern and *blazingly fast* typesetting system Typst 
//
Equations can be typeset inline like $f_"a"(x)$, and in display mode:

$
                             curl E & = - pdv(B, t) \
  integral.cont_(partial A) E dd(s) & = - integral.double_A pdv(B, t) dd(A)
$

By adding a label

$
  e^("i" pi) + 1 = 0
$ <eq:mycustomlabel>

they can be referenced as in @eq:mycustomlabel.
The same works for @fig:example.
@fig:example[Figure] comes before @fig:rect[Figs.] and @fig:lilaq[].
Referring to @sec:test or the data in @tab:parameters is also possible.


#figure(
  placement: bottom, // `top`, `bottom` or `auto` for floating placement or `none` for inline placement
  rect(width: 100%, height: 5cm, fill: gradient.linear(
    ..color.map.crest,
    angle: 140deg,
  )),
  caption: [
    A placeholder figure with a linear gradient @TheLawOfLeakyAbs
  ],
) <fig:example>



= Section
== Subsection <sec:test>
#lorem(100)

壁垒击穿效应。*由于 AI 编码的应用*，IT 行业的人才更替周期已经剧变，好在行业整体需求量暂
时并未增长过多，否则我将在五年内面临比现在和以往严重的多的学历歧视。实际上绞肉机已经开始了，好比地表空气的整体成分发生了不算微小的突变，它不会影响你今天的生活，却会改变千年后人类整体的生物特征。另一个会快速迎来剧变的行业是教育，我不知道其他行业的价值如何，但在此次生成式 AI 浪潮下，这两个行业的变化意义是显著的。熵增开始了
== Subsection
#lorem(100)


#figure(
  placement: top,
  // @typstyle off
  revtable("rl", header: left,
    stroke: (x, y) => if x==0 {(right: black + 0.5pt)},

    [ Ion       ],[ Carbon $attach("C", tl: 12, tr: 6+)$ ],
    [ Frequency ],[ $f_"a" = "1~GHz"$ ],
    [ Bandwidth ],[ $Delta f_1 = 0.01 f_"a"$ ],

  ),
  caption: [
    Parameters
  ],
) <tab:parameters>


#figure(
  scope: "parent", // two column-figure
  placement: top, // `top`, `bottom` or `auto`
  box(
    fill: gradient.linear(..color.map.flare, angle: 120deg),
    width: 100%,
    height: 2cm,
  ),
  caption: [
    A column spanning figure. #lorem(25)
  ],
) <fig:rect>


= Packages

The Typst ecosystem features a broad range of community driven packages to make writing papers with Typst even more convenient.
These can be found by exploring the Typst Universe at https://typst.app/universe.

// See the import section near the top of this document


== Physical quantities

The *zero* package helps typesetting numbers and scientific quantities.

//#zero.set-num(uncertainty-mode: "compact")
#let quantify(
  zero-options: (
    product: sym.dot,
    omit-unity-mantissa: true,
    fraction: "inline",
  ),
  body,
) = {
  let q(value, unit) = zero.zi.declare(unit.text)(value.text, ..zero-options)
  let rnum = "[-\u{2212}]?\d+(?:.\d+)?(?:\+(?:\d+(?:.\d+)?)?-\d+(?:.\d+)?)?(?:e-?\d+)?"
  let runit = "[a-zA-ZΩµ%°^\d*/]+"
  let expression = regex("(" + rnum + ")[\u{00A0}~](" + runit + ")")
  show expression: it => {
    //set text(fill: blue)
    let (value, unit) = it.text.match(expression).captures
    unit = unit.replace("*", " ")
    q[#value][#unit]
  }
  body
}
#show: quantify

Using the custom show-rule above, quantities are nicely formatted
including thin spaces between the number and unit like in 1.2~µm,
digit grouping for $x = "0.12345678~m"$,
uncertain quantities like $f_"rev" = "325.2+-0.1~kHz"$
as well as tolerances such as $h = "8.3+0.1-0.2e-2~mm"$.
//
For details refer to the documentation at https://typst.app/universe/package/zero.




== Plots

With the *lilaq* package, plots can be create directly in the document, so you can skip the additional plotting step in your workflow while ensuring that all plot elements are properly sized.
@fig:lilaq gives an example and the full documentation is available at https://lilaq.org.

// general plot styling options
#show lq.selector(lq.diagram): set text(.9em)
#show: lq.set-tick(outset: 3pt, inset: 0pt)
#show: lq.set-diagram(
  xaxis: (mirror: (ticks: false)),
  yaxis: (mirror: (ticks: false)),
)

#figure(
  placement: auto,
  lq.diagram(
    // plot a sine function
    let x = lq.linspace(0, 10),
    let y = x.map(x => calc.cos(x)),
    lq.plot(x, y, mark: none, label: [$cos(x)$]),

    // plot some data (practically you can load data from a file using `json` etc.)
    lq.plot(
      (1, 2, 3, 7, 9),
      (-1, 1.8, 0.7, -0.3, 1),
      yerr: 0.3,
      mark: "o",
      stroke: (dash: "dashed"),
      label: [Data],
    ),

    // adjust plot layout
    height: 3cm,
    xlabel: [Angle ~ $x$ / rad],
    xlim: (0, 10),
    ylabel: [$y$ / m],
    ylim: (-1.5, 2.5),
  ),
  caption: [
    A plot create with Lilaq.
  ],
) <fig:lilaq>




== Abbreviations

The *glossy* package helps managing abbreviations,
automatically using the long form on first use of @APS
and the short form on subsequent uses of @APS.
But it can do much more:
@RF:a:cap device shows how capitalization is applied on sentence start, and in addition the article (a/an) is managed automatically, since it differs between the first and subsequent use of @RF:a device.
In addition, explicit forms are supported as in @RF:long, @RF:short and @RF:both,
and plural forms can be accessed like in @RF:pl.
For more details, refer to https://typst.app/universe/package/glossy.



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



