#import "@preview/basic-document-props:0.1.0": simple-page
#show: simple-page.with("刌刈", "isirin1131@outlook.com", middle-text: "每日读书笔记", date: true, numbering: true, supress-mail-link: true)

#set text(font: ("Sarasa Fixed Slab SC"), lang:("zh"))

#show math.equation: set text(font: "Neo Euler")

= 泛函导论 Erwin 

== 1.2

1.2-1 的 d 本身暂时不重要。记一下 $f'>=0 and A >= B -> f(A)>=f(B)$ 这个 trick。对大学生喜闻乐见但我只是个大专生。

1.2-2 用了 1.1 节习题 6 的解法。

1.2-3 的 (d) 又在用类似 $|A|<=|B+C| -> [root(n, |A|)]^n <= [root(n, |B+C|)]^n$ 的东西，

=== 习题

1. 收敛序列按下标相乘还是收敛的。
2. p = 2 时 q = 2，代入即可。
3. [😢] 不会。无限序列的结论如何导出有限序列的结论？
4. [#text(red)[❌]]$a_n = n$
5. 调和级数
6. 显然，略。
7. 同上
8. M1 自然满足，M2 不满足。M3 满足，M4 不满足（构造 $A subset.eq C and B subset.eq C and A inter B = emptyset$ 即可）
9. [#text(red)[❌]]两个命题都显然，略。
10. [😢] x,y 至少一个在 B 内时显然；其余情况下，如果 B 为单点，实际上就是三角不等式的变体，所以这道题的观点实际上就是一种类欧几里得空间的洞察。但我不会。
11. $f(t) = t/(1+t)$ 单调递增故 $A<=B+C => f(A)<=f(B+C)$，而实际上有 $f(B+C)<=f(B)+f(C)$，故三角不等式成立。($B>0 and C>0$，实际上这个论证正文 1.2-1 里也有)；而 $t/(1+t)$ 在 $R_(>=0)$ 上是有上下确界的。
12. 看三角不等式即可。其实用欧几里得空间式的直觉就可以想象出来，说明三角不等式代表本质。
13. 推一下即可。
14. [😢] 似乎类似闵可夫斯基不等式，但不会。
15. $max(A+B,C+D) <= max(A,C) + max(B,D)$ 对任意实数恒成立。

看了题解。3 居然是这样解决的吗，太厉害了。4 我忽略题目条件了，蠢。9……奇怪的边界条件吗？不懂

我不知道当时为啥对 10 束手无策。

14 的这个符号运用我只能说 oh my gosh，不懂。

习题是我在几乎没读 1.2-3 的情况下做的，说明这一节真正重要的只有那三个公式。

欠着先，用到再说。