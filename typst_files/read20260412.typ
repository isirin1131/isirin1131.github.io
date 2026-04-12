#import "@preview/basic-document-props:0.1.0": simple-page
#show: simple-page.with("刌刈", "isirin1131@outlook.com", middle-text: "每日读书笔记", date: true, numbering: true, supress-mail-link: true)

#set text(font: ("Sarasa Fixed Slab SC"), lang:("zh"))

#show math.equation: set text(font: "Neo Euler")

= 泛函导论 Erwin

== 2.3

这章看上去有点短，学术风格是不是浓了一些？虽然全扔到习题里了。直接做题吧。

== 习题

1. 验证一下收敛性。
2. 略
3. 封闭性显然，但可以构造一个收敛到外面的 cauchy 序列
4. 不会
5. 略
6. 假设不在，推出不是闭包。
7. 直接验证就行了，还是那个经典的收敛实数级数序列。所谓绝对收敛的概念更多是一种数值上的评估，跟向量空间的完备与否没有关系。
8. $sum_(n<=i<=m) norm(x_i)>=norm(sum_(n<=i<=m) x_i)$，所以一个绝对收敛的序列必然对应一个 Cauchy 序列。
9. 同 8.
10. 这个 base 组成的向量空间显然在 $X$ 中是稠密的。
11. 显然。
12. 第一小段 2.2 的第四个习题证过；第二个还是那个三角不等式。这题在炒冷饭？
13. 14. 关联不大。14. 更关注给商空间的元素陪集定义范数，13. 则意在说明半范数中的 “零等价类” 在范数的视角上可以看作零。
15. 咕咕嘎嘎。

有点懒。稍微看一下答案。4. 复习一下哈哈。


#bibliography("ref.bib")