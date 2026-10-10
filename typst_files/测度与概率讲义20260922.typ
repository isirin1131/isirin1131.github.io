#import "@preview/basic-document-props:0.1.0": simple-page
#import "@preview/cetz:0.5.2"
#show: simple-page.with("枕戈", "isirin1131@outlook.com", middle-text: "测度与概率", date: true, numbering: true, supress-mail-link: true)

#set text(font: ("Sarasa Fixed Slab SC"), lang:("zh"))

#outline()

= 测度的基本定义

== 三种代数系统

对于一个基本元素为集合的代数系统 $Alpha$，其元素一般为某个全集 $S$ 的幂集 $cal(P)(S)$ 的子集，且要求 $S in Alpha$。

$Alpha$ 要求其中的元素 $X in Alpha$ 对补集 $X^"c"$ 封闭，如果同时要求对有限并封闭，则称 $Alpha$ 为集合代数；同时要求对可数并封闭，则称 $Alpha$ 为 $sigma$ 代数；同时要求对不可数并封闭，则称 $Alpha$ 为完全布尔代数。

由于补集和并集可以组合成交集、差集和对称差等运算，所以这三种代数系统的实质区别是*允许怎样规模的集合运算*。

它们的关系大致是：

$
  text("集合代数") subset sigma text("代数") subset text("完全布尔代数")
$

这三者都非常有用。

== 测度的历史：结构主义视角

类似范数意在定义向量的大小，测度 $mu$ 是一种 `set 2 non-negative number` 的函数，意在定义集合的大小。

描绘代数空间的是空间中的运算，故而线性运算之于向量空间才是主要部分，而向量本身并不太重要，范数的公理也主要围绕着线性运算来定义。同样地，测度亦是由公理所定义，它们围绕着集合运算描述。

范数与测度的公理和它们所在的代数空间一样，也是抽象出来的。

测度的公理除了 $mu(emptyset)$ 外，只有一条*可数可加性*，也即对两两不交的集合序列 $(x)_n$，需要满足 $mu(limits(union.big)_(i=1)^infinity x_i) = limits(union.big)_(i=1)^infinity mu(x_i)$，这天然要求测度所依赖的代数空间是 $sigma$ 空间。

至于为什么测度的公理是可数可加性而非有限可加性和不可数可加性，那就是一段很长的历史了，建议读者在一个悠闲的下午溯流而上，这里就不再展开。

== 具体定义体系

集合 $S$ 和其上的 $sigma$ 代数 $cal(F)$ 的二元组 $(S,cal(F))$ 被称为*可测空间*，$f in cal(F)$ 被称为*可测集*。

$mu:cal(F) arrow [0,infinity]$ 被称为测度，当且仅当：

#rect()[
  1. $mu(emptyset) = 0$ 2. 对任意两两不交的可测集序列 $(f)_n$，有：$mu(limits(union.big)_(i=1)^infinity f_i) = limits(union.big)_(i=1)^infinity mu(f_i)$
]

$(S,cal(F),mu)$ 被称为*测度空间*。

#pagebreak()

= 测度下的概率体系

概率测度空间一般写为 $(Omega,cal(F),P)$，其要求 $P(Omega) =1$，很符合直觉。

$Sigma$

asda

