#import "@preview/basic-document-props:0.1.0": simple-page
#import "@preview/cetz:0.5.2"
#show: simple-page.with("枕戈", "isirin1131@outlook.com", middle-text: "epsilon-delta 语言", date: true, numbering: true, supress-mail-link: true)

#set text(font: ("Sarasa Fixed Slab SC"), lang:("zh"))

#show math.equation: set text(font: "Neo Euler")

#outline()

= 引言

众所周知，在数学中一旦涉及到 “无限”，就会出现各种看似反直觉的现象，比如 $1-0.99999dots$ 是什么？这个问题用无限不循环小数的符号体系很难回答，因为你无法解释 “无限个零的尾端有一个一” 这件事中为什么无限个零还会有尾端。但学习了 $epsilon-delta$ 语言（epsilon-delta 语言）后建立了实数集的概念和体系，我们可以精确地描述它。

另一个例子是开集和闭集，为什么 $(0,1) subset [0,1]$，右边的比左边的多两个元素（$(0,1) union {0,1} = [0,1]$），但左边的被叫做开集右边的被叫做闭集？这实际上就是 “无限趋近于边界” 时各种奇怪行为的体现，比如开集的所有元素都有一个不为零的邻域，而闭集在边界上的元素没有。“开闭之争” 是拓扑学的基础，这里不再赘述。

#rect()[
$epsilon-delta$ 语言是一种工具，用于形式化地描述分析学中与 “无限”（无穷大，无穷小，无限接近） 相关场景中的各种行为。
]

这套语言并不是唯一的方式，如一类使用超实数体系的非标分析也可以达到同样的效果（详见莱布尼兹原理），所以真正重要的是 *“形式化”*，也即用形式语言严格地、去掉模糊空间地、不多不少地描述一类事情。

#pagebreak()

= 首次接触 epsilon-delta 语言


== 一类简单的收敛行为

这类行为基本是 “随着 x 增大，f(x) 逐渐接近于 A”。有的函数单调地趋近（如 @fig:converge），有的则在趋近过程中来回震荡（如 @fig:osc）。我们要在形式话描述这种行为的过程中引出 $epsilon-delta$ 语言。

#figure(

cetz.canvas(length: 2cm, {
  import cetz.draw: *

  set-style(
    mark: (fill: black, scale: 2),
    stroke: (thickness: 0.4pt, cap: "round"),
    content: (padding: 1pt)
  )

  grid((0, 0), (4, 4), step: 0.5, stroke: gray + 0.2pt)

  line((-0.2, 0), (4.5, 0), mark: (end: "stealth"))
  content((4.5, 0), $ x $, anchor: "west")
  line((0, -0.2), (0, 4.3), mark: (end: "stealth"))
  content((0, 4.3), $ y $, anchor: "south")

  for (x, lbl) in ((0, "1"), (1, "10"), (2, "100"), (3, "1000"), (4, "10000")) {
    line((x, 3pt), (x, -3pt))
    content((x, -3pt), anchor: "north", lbl)
  }

  for y in (1, 2, 3, 4) {
    line((3pt, y), (-3pt, y))
    content((-3pt, y), anchor: "east", str(y))
  }

  line((3pt, 3.14), (-3pt, 3.14))
  content((-3pt, 3.14), anchor: "east", $ 3.14 $)

  set-style(stroke: (thickness: 0.4pt, paint: gray, dash: "dashed"))
  line((0, 3.14), (4, 3.14))

  set-style(stroke: (thickness: 1.2pt, paint: blue))
  let pts = ()
  let n = 500
  for i in range(n + 1) {
    let x = 10000 * i / n
    pts.push((calc.ln(x + 1) / calc.ln(10), 3.14 - 2 / (x + 1)))
  }
  line(..pts)

  content((2, 3.6), text(blue)[$ f(x) = 3.14 - 2/(x+1) $], anchor: "west")
}),

caption: [简单的收敛]
) <fig:converge>

#figure(

cetz.canvas(length: 2cm, {
  import cetz.draw: *

  set-style(
    mark: (fill: black, scale: 2),
    stroke: (thickness: 0.4pt, cap: "round"),
    content: (padding: 1pt)
  )

  grid((0, 0), (4, 4), step: 0.5, stroke: gray + 0.2pt)

  line((-0.2, 0), (4.5, 0), mark: (end: "stealth"))
  content((4.5, 0), $ x $, anchor: "west")
  line((0, -0.2), (0, 4.3), mark: (end: "stealth"))
  content((0, 4.3), $ y $, anchor: "south")

  for (x, lbl) in ((0, "1"), (1, "10"), (2, "100"), (3, "1000"), (4, "10000")) {
    line((x, 3pt), (x, -3pt))
    content((x, -3pt), anchor: "north", lbl)
  }

  for y in (1, 2, 3, 4) {
    line((3pt, y), (-3pt, y))
    content((-3pt, y), anchor: "east", str(y))
  }

  line((3pt, 2.0), (-3pt, 2.0))
  content((-3pt, 2.0), anchor: "east", $ 2 $)

  set-style(stroke: (thickness: 0.4pt, paint: gray, dash: "dashed"))
  line((0, 2.0), (4, 2.0))

  set-style(stroke: (thickness: 1.2pt, paint: red))
  let pts = ()
  let n = 500
  for i in range(n + 1) {
    let x = 10000 * i / n
    pts.push((calc.ln(x + 1) / calc.ln(10), 2 + 4 * calc.sin(x) / (x / 20 + 1)))
  }
  line(..pts)

  content((2, 3.6), text(red)[$ f(x) = 2 + 4\,sin(x)/(x/20 + 1) $], anchor: "west")
}),

caption: [震荡收敛]
) <fig:osc>

== 精确描述

或者说，把一句自然语言逐渐变成完全的形式化表达。

=== 描述“接近”

起点是一句自然语言————
#quote(block: true)[
  随着 $x$ 增大，$f(x)$ 逐渐无限接近于常数 $A$。
]

“接近”首先是一个距离概念，因此直觉上可以这么改：

#quote(block: true)[
随着 $x$ 增大，$|f(x) - A|$ 逐渐无限变小。
]

但这个说法只能覆盖 @fig:converge 的行为，它描述了一种 $|f(x) - A|$ 平滑降低的过程，跟 @fig:osc 这种数值震荡的行为对不上（况且很多随 x 增大而收敛的函数比 @fig:osc 震荡多了）。

这说明这一版改的太过了，实际上我们之所以能明确看出 @fig:osc 也收敛，是因为虽然 $f(x)$ 随着 $x$ 的增大一直在 $A$ 周围震荡，但震荡的幅度是在逐渐减少的。因此我们实际上是想表达：

#quote(block: true)[
随着 $x$ 增大，$|f(x) - A|$ 的数值范围逐渐无限变小。
]

=== 描述“数值范围”

当定义域为 $x in [0,infinity)$ 时，$|f(x)-A|$ 的数值范围，也就是它的上下界，其实是固定的。

那么为什么我们直觉上认为在 $x$ 增大时会有一个随之变小的数值范围呢？实际上我们本能上把定义域 $[0,infinity)$ 看成了 $[0,x]$ 和 $[x,infinity)$ 两部分，而我们认为那个随 $x$ 增大一直在缩小的数值范围实际上是把定义域看成 $x in[x,infinity)$ 时的数值范围。

因此下一步的改进是：

#quote(block: true)[
随着 $x$ 增大，$sup{|f(hat(x)) - A|}$（$hat(x) in [x,infinity)$）逐渐无限变小。（当然 $inf{|f(x) - A|}$（$x in [x,infinity)$）是恒为 $0$ 的）
]


#rect()[
  *补充：*
实际上对于 $x=1,2,3,4,dots$，有 $[1,infinity) supset [2,infinity) supset [3,infinity) supset [4,infinity) supset dots$，也就是说随着 $x$ 增大，我们本能地关注的那个定义域 $[x,infinity)$ 在不断 “缩小”，在此过程中，$|f(x)-A|$ 的下界固定为 0，而上界天然单调不减。
]

=== 描述“无限变小”

所谓无限变小，就是不能变小到一定程度就不变小了。用形式语言描述就是不存在 $epsilon>0$ 使得不管 $x$ 多大 $sup{|f(hat(x)) - A|}$（$hat(x) in [x,infinity)$）都大于 $epsilon$。换句话说就是对于任意 $epsilon>0$ 都至少存在一个 $x$ 使得 $sup{|f(hat(x)) - A|}$（$hat(x) in [x,infinity)$）小于 $epsilon$（基于上节补充内容，此时对所有 $y>x$ 也有 $sup{|f(hat(y)) - A|}$（$hat(y) in [y,infinity)$））

因此可以进一步改成：

#quote(block: true)[
随着 $x$ 增大，$sup{|f(hat(x)) - A|}$（$hat(x) in [x,infinity)$）逐渐小于任意 $epsilon>0$
]


=== 描述“随着……逐渐……”

“随着……逐渐……” 是一个过于细节的视角，是把 $x$ 从 $0$ 到 $infinity$ 一点一点看过去的。基于上上节的补充内容，$sup{|f(hat(x)) - A|}$（$hat(x) in [x,infinity)$）是单调不减的，虽然我们能保证它最终可以小于任意 $epsilon>0$，但完全可能出现把 $x$ 增大了很多之后 $sup{|f(hat(x)) - A|}$（$hat(x) in [x,infinity)$）才迟迟变小一点的情况。故而可以 “跳步”，只关注那些实质性让 $sup{|f(hat(x)) - A|}$（$hat(x) in [x,infinity)$）变小的 $x$。

进一步地，甚至也不需要关心那些能让 $sup{|f(hat(x)) - A|}$（$hat(x) in [x,infinity)$）变小的 $x$，因为它们并不是独一无二的（还记得上一节中括号内的那一句此时对所有 $y>x$ 也有 $sup{|f(hat(y)) - A|}$（$hat(y) in [y,infinity)$）吗？），它们只需要存在即可，而 “随着 $x$ 增大，$sup{|f(hat(x)) - A|}$（$hat(x) in [x,infinity)$）逐渐小于任意 $epsilon>0$” 本身就确保了它们存在，真正值得关心的就只有 $sup{|f(hat(x)) - A|}$（$hat(x) in [x,infinity)$ 的变小。

所以有了一个等效于标准答案的版本：

#quote(block: true)[
对任意 $epsilon>0$，都存在 $x$，使得 $sup{|f(hat(x)) - A|}<epsilon$（$hat(x) in [x,infinity)$）
]

=== 所以，标准答案是？

除了把任意换成 $forall$，把存在换成 $exists$，还得把 $sup{|f(hat(x)) - A|}<epsilon$（$hat(x) in [x,infinity)$） 换成 $forall hat(x)>x$，$|f(hat(x))-A|<epsilon$，最后的标准版写成这样：

#align(center, rect()[
$ forall epsilon > 0, exists x, space forall hat(x) > x, space |f(hat(x)) - A| < epsilon. $
])



= Cauchy 对收敛的描述方式

= 描述无穷大

= 描述函数的不连续之处

= 扩展题：复函数的收敛