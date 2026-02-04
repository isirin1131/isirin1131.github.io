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
    FlowWrite 开发简述与技术报告
  ],

  // Author list
  authors: (
    (name: "田照涛. Author", at: "uni", email: "mail@example.com"),
    (name: "P. Coauthor", at: ("uni", "third"), orcid: "0000-0000-0000-0000"),
    (name: "J. Cockcroft", at: ("INP", "third")),
    (
      name: "C. D. Anderson",
      at: "INP",
      note: "Present address: Home Office, City, Country",
    ),
    (names: ("N. Bohr", "A. Einstein", "M. Curie", "E. Lawrence"), at: "INP"),
    //(names: ("A. Group", "O. F. People"), at: "Single Use Primary Affiliation, Shortcut Way"),
  ),
  affiliations: (
    uni: [#link("https://ror.org/...")[贵州轻工职业大学], 贵州, 中国],
    INP: [#link("https://ror.org/...")[Institute of Nobel Physics], Stockhold, Sweden],
    third: "The Third Institute, City, Country",
  ),
  group-by-affiliation: true,

  // Paper abstract
  abstract: [
    不过，计算机科学的核心是证明（递归）、算法（递归）、编程语言（λ演算）、操作系统（指针）、编译器（λ演算）——所以归根结底，一所不教 C 语言也不教 Scheme 的 Java 学校，其实也算不上真正意义上的计算机科学。函数柯里化这个概念在现实世界中或许毫无用处，但它显然是计算机科学研究生院的先决条件。我不明白，为什么计算机科学院校的课程委员会成员会允许他们的课程被简化到这种程度，以至于不仅培养不出合格的程序员 ，甚至连能拿到博士学位、能和他们竞争工作的计算机科学研究生都培养不出来。哦，等等。算了。也许我明白了。

  ],

  // Other optional information
  date: [(Drafted #datetime.today().display("[day] [month repr:long] [year]");)],
  //doi: "https://doi.org/10.1103/PhysRevAccelBeams.00.000000",
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
    Licensed under the terms of the
    #link(
      "https://creativecommons.org/licenses/by/4.0/",
    )[Creative Commons Attribution 4.0 International]
    license. Further distribution of this work must maintain attribution to the authors and document title.
  ],
  //wide-footnotes: true,

  // Writing utilities
  //show-line-numbers: true,
)

#set text(
  // 英文优先使用 New Computer Modern (学术巅峰)
  // 中文自动回退到 Source Han Serif (现代正式)
  font: ("New Computer Modern", "Source Han Serif SC"),
  size: 10.5pt, // 相当于中文五号字
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



= Introduction

This is a template for submission of manuscripts to @PRAB // abbreviation
using the great, modern and *blazingly fast* typesetting system Typst @sillyTalkUnderMoon
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
时并未增长过多，否则我将在五年内面临比现在和以往严重的多的学历歧视。实际上绞肉机已经开
始了，好比地表空气的整体成分发生了不算微小的突变，它不会影响你今天的生活，却会改变千年
后人类整体的生物特征。另一个会快速迎来剧变的行业是教育，我不知道其他行业的价值如何，但
在此次生成式 AI 浪潮下，这两个行业的变化意义是显著的。熵增开始了
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








#show heading: set heading(numbering: none)

= ACKNOWLEDGMENTS

We thank ...


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



