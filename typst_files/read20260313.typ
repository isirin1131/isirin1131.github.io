#import "@preview/basic-document-props:0.1.0": simple-page
#show: simple-page.with("刌刈", "isirin1131@outlook.com", middle-text: "每日读书笔记", date: true, numbering: true, supress-mail-link: true)

#set text(font: ("Sarasa Fixed Slab SC"), lang:("zh"))

#show math.equation: set text(font: "Neo Euler")

= 泛函导论 Erwin

== 1.6

$QQ$ 到 $RR$ 的完备化就像是只经历了一次闭包运算，因此 $QQ$ 在 $RR$ 中显现的稠密性是很自然的，因为聚点的定义就是如此。嗯哼，1.6-2 也在说这点。

这节似乎只是复述一遍 $QQ -> RR$ 的过程？不管了。语言风格有点顶不住。

=== 习题

1. 此时的 Cauchy 序列必然会在足够远的地方呈现 $a,a,a,a,a,...$ 的形态，从而所有 Cauchy 序列都会收敛在 $Y$ 里。
2. $RR$，这个答案在我们的 DNA 里。
3. 它本身吧，这里仍然有习题 1 的现象。这种现象之前的习题好像提了不少次。
4. 显然。等距是以一一对应为前提的。
5. a 太显然了。b 的话，$T:QQ->RR, T x = x+1$，
6. $T:C[a,b]->C[0,1],T (f[x] = y) = (f[(x-a)/(b-a)]=y)$，至于等距性自然是显然的
7.8. $d->tilde(d)$ 基本就是将值域做了 $[0,infinity)->[0,1)$ 的变换，且 $d(x,y)<epsilon <-> tilde(d)(x,y)<epsilon$
9. $abs(x_n-x_n^')<epsilon and abs(x_n-l)<epsilon -> abs(x_n^' -l)<=2epsilon$
10. 类似习题 9.
11. 自反性对称性交换性
12. $abs(x_n-x_m)<epsilon and abs(x_n-x_n^')<epsilon and abs(x_m-x_m^')<epsilon -> abs(x_n^'-x_m^')<=3epsilon$
13. $x!=y and d(x,y)=0$ 可以同时为真。这个例子验证非常简单。
14. [#text(red)[❌]]度量。
15. 简，略。

看下答案。5. 中我的考虑应该有所不周，但不管了。14. 我不是很懂，不过懒得查了。



#bibliography("ref.bib")