#import "@preview/basic-document-props:0.1.0": simple-page
#show: simple-page.with("刌刈", "isirin1131@outlook.com", middle-text: "每日读书笔记", date: true, numbering: true, supress-mail-link: true)

#set text(font: ("Sarasa Fixed Slab SC"), lang:("zh"))

#show math.equation: set text(font: "Neo Euler")

= 泛函导论 Erwin

我嘞个最重要，特别有用和最为完善啊，这不是高级线代？

况且算子和泛函都离不开赋🍚空间。

== 2.1

和众多线代书的叙述大同小异，但显然过于概要了，不必多说。

=== 习题

1. 验证即可。
2. $0x=(a+-a)x=theta$，$alpha theta=alpha(0 x)=(alpha 0)x=theta$，$(-1x)+x=(-1)x+1x=(-1 + 1)x=0x=theta -> -1x=-x$
3. ${(a,a,a+2b) mid(|) a,b in RR}$
4. only (a)
5. 令 $x -> infinity$ 便可轻易制造反例。
6. 不同的表达式相减可以导出基向量组的一个线性相关表达式
7. $alpha e = (a+b i)e = a e + b i e$，因此 n 和 2n 是答案。
8. [🤓]很难说，似乎要分很多情况，懒得搞。
9. 考虑类似习题 5 的基，然后对于 $n+2$ 个元素，用基于鸽笼原理的递归算法即可得出必然线性相关。不是子空间，因为标量还是复数。
10. 逻辑上成立，举例的话…… ${(a,0)}$ 和 ${(0,b)}$ 吧？不全面但懒得搞了。
11. 显然
12. 奇异矩阵对加法不封闭
13. 慢慢验证即可。
14. 对 $x in X and x in.not Y and forall y in Y$ 来说，$(y-x) + Y$ 作为陪集可以覆盖 $x$，看图后很自然的猜想是陪集之间要么完全相等要么相交等于空集，下个小题目的证明是显然的，但这个猜想不显然，但两者结合是在试图阐明子空间本质上是原空间去掉了一些维度。#rect()[
    证明：考虑 $Y$ 的一个 base $hat(e)={e_1,e_2,...,e_n}$，对于任意 $x in X$，定义 $x-hat(e)={x-alpha_1 e_1-alpha_2e_2-dots-alpha_n e_n mid(|) alpha_j in K}$（$K$ 是标量集合），也就是说，$v in x-hat(e)$ 定义的陪集 $v+Y$ 中都会包含 $x$，且包含 $x$ 的陪集都在这个集合中，考虑 $v_1,v_2 in x-hat(e)$，可以发现 $v_1+Y$ 和 $v_2+Y$ 是完全相同的，故 $x-hat(e)$ 定义了一个陪集的等价类，考虑不同的两个等价类是否有交点，设 $z=v_1+Y=v_2+Y$，则 $v_1=v_2=z-hat(e)$，所以不同的等价类陪集完全没有交点。这和前面所述的可覆盖性结合就说明了陪集可以将 $X$ 划分。
] 
15. 简，略。

对对答案。没啥营养。


#bibliography("ref.bib")