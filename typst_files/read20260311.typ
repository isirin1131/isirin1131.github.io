#import "@preview/basic-document-props:0.1.0": simple-page
#show: simple-page.with("刌刈", "isirin1131@outlook.com", middle-text: "每日读书笔记", date: true, numbering: true, supress-mail-link: true)

#set text(font: ("Sarasa Fixed Slab SC"), lang:("zh"))

#show math.equation: set text(font: "Neo Euler")

= 泛函导论 Erwin

== 1.5

深度学习的数学知识壁垒不会是泛函而非线性代数吧？

这节符号看着头疼本来想跳的，但看到下节也是完备性就知道这玩意重要了，只能硬着头皮看。

虽然实际上挺简单的，1.5-1、1.5-2 和 1.5-4 的核心思想都是按每个维度拆除来看，细枝末节不重要。

1.5-3 很绕，可以概括为一个由收敛序列组成的收敛序列，收敛到一个收敛序列。（其实这里闭包没用）

一致收敛问了 ai，关于所谓收敛速度不一致为什么不能取每个点的 $N$ 的 $max$，是因为一个无限集虽然可能每个数都是有限的，但也可以没有上确界。

1.5-7 构造一个 $x_n = (floor pi times 10^n floor.r) / 10^n$ 即可。

1.5-8 多项式拟合神教哈哈哈，超绝大闭包

1.5-9 的叙述有点怪？但懒得想了。

=== 习题

1. 简单，略。
2. #rect()[
    取 $X$ 中元素组成的任意 Cauchy 序列 $(x)_n$，满足对任意 $epsilon>0$ 都存在 $N>0$ 使得对任意 $n,m>N$ 都有 $d(x_n,x_m) = limits(max)_j abs(zeta^n_j - zeta^m_j) < epsilon$，可以导出对任意 $j$ 有 $abs(zeta^n_j - zeta^m_j) < epsilon$，故 $(zeta_j^(1,2,3,...,infinity)) -> zeta_j$，可以定义 $hat(x) = (zeta_1, zeta_2, ..., zeta_n)$，…………………… 不写了。
]
3. 考虑 $l^infinity$ 的度量 $limits(sup)_j abs(xi_j-eta_j)$，可以构造 $x_1=(1,0,0,...),x_2=(1,1/2,0,...),x_3=(1,1/2,1/3,0,...),...$，在这样的度量下，我们构造的这个序列明显是柯西序列，然而它却收敛到一个有无限个非零项的序列。
4. 不也一样吗。
5. 这个度量下的柯西序列中必然存在 $abs(n-m)<1 -> n=m$，因此收敛到的也是整数
6. 注意 $arctan x$ 是有上确界的，所以可以很自然地让 $(1,2,3,4,...)$ 成为这个度量下的柯西序列，但这个序列即使在这个度量也下并不收敛到某个实数。
7. 这个和上题差不多。
8. 对于度量 $limits(max)_(j in J) abs(x(j)-y(j))$，$Y$ 中的柯西序列 $(x)_n$ 满足 $abs(x_n (j)-x_m (j))<epsilon$（原谅我省略了一些叙述），包括 $j=a or b$ 的时候，故此一致收敛是有的，而收敛到的这个 $x$，也有 $abs(x(a)-x(b))<=abs(x(a)-x_n (a))+abs(x_n (a)-x_n (b)) + abs(x_n (b)-x(b)) = 2epsilon$（原谅我省略了太多叙述，但实在麻烦）
9. 连续函数序列 $(x)_n$ 在 $[a,b]$ 上一致收敛：#underline()[对任意 $epsilon>0$，存在 $n,m>N$ 使得对所有 $j in [a,b]$ 有 $abs(x_n (j)-x_m (j))<epsilon$（实际上这个度量就蕴含了一致收敛）]，至于连续性的证明，还是三角不等式。$abs(x(j_0)-x(j))<=abs(x(j_0)-x_n (j_0))+abs(x_n (j_0)-x_n (j))+abs(x_n (j)- x(j))=3epsilon$
10. 见习题 5.
11. 其实看度量函数就知道，收敛还是要个个过关，虽然后面的项权重很小，但还是要。从 $1/(2^j)(abs(xi_j-eta_j))/(1+abs(xi_j-eta_j))<epsilon$ 可以推出 $|xi_j - eta_j| < cases(
  frac(2^j epsilon, 1 - 2^j epsilon) & "当" 2^j epsilon < 1,
  +infinity & "当" 2^j epsilon >= 1
)$，证毕；另一个方向，虽然不是一致收敛，但后面的项权重越来越小，也是可以收敛的。
12. 显而易见
13. 想象不出来，geogebra 也画不出来……饿啊啊
14. 
15. 巴塞尔问题的余项收敛到零，因此是柯西序列。至于不收敛是显然的。

看看答案。

14 题看着头疼不妨跳过。我的风格似乎还不太喜欢应用尽用前面给到的定理而是硬上，看来还是毒打吃少了。


#bibliography("ref.bib")