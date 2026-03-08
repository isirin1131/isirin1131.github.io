#import "@preview/basic-document-props:0.1.0": simple-page
#show: simple-page.with("刌刈", "isirin1131@outlook.com", middle-text: "每日读书笔记", date: true, numbering: true, supress-mail-link: true)

#set text(font: ("Sarasa Fixed Slab SC"), lang:("zh"))

#show math.equation: set text(font: "Neo Euler")

= 泛函导论 Erwin

== 1.4

又到了最喜欢的微积分环节。

别忘了任意两个数之差 $<epsilon$ 是收敛的另一种表述。

所以本节最重要的概念还是完备性，我之前真没听说过。既然是直接由 cauchy 序列来定义完备性，说明 cauchy 序列的这种两个数之差的表述是比收敛更加底层的东西。

啊我懂了，如果在某种度量下空间有洞，也可以说不稠密，那么柯西序列就不收敛。 好吧完备性其实在说一件很简单的事情。

感觉 1.4-8 比 1.3-4 直观些啊。

=== 习题

1. 太简单，略。
2. 用 1. 的结论。
3. 这不是把收敛的定义复述了一遍？
4. 取 $epsilon = 1$，对任意 $n,m>N$ 有 $d(x_n,x_m)<1 -> d(x_(N+1),x_n)<1$，以 $x_(N+1)$ 为两个集合的交点，配合三角不等式即可证明。
5. 随便构造反例。
6. $d(x_n,y_n)<=d(x_n,y_m)+d(y_n,y_m)<=d(y_n,y_m)+d(x_n,x_m)+d(x_m,y_m)$。
其实就是可以让 $d(y_n,y_m)+d(x_n,x_m)$ 任意小，从而让 $|a_n-a_m|$ 任意小。

7. 想到了前几节的一个点对集合的距离函数。不懂如何间接证明。
8. 太简单，略。
9. 15 和 13 以 1,2 为 a,b；14 和 13 以 1 和 1/2 为 a,b 大概就够了，这里的估算是对 1/2 的。
10. 考虑 $[z]_n = [a]_n + i[b]_n$，关键一步是 $CC$ 中的柯西序列很容易对应到 $RR$ 中的两个柯西序列。

没啥好说的，纯概念节。

#bibliography("ref.bib")