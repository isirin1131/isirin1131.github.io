#import "@preview/basic-document-props:0.1.0": simple-page
#show: simple-page.with("刌刈", "isirin1131@outlook.com", middle-text: "每日读书笔记", date: true, numbering: true, supress-mail-link: true)

#set text(font: ("Sarasa Fixed Slab SC"), lang:("zh"))

#show math.equation: set text(font: "Neo Euler")

= 泛函导论 Erwin

== 2.2

2.2.2 是三角形两边之差不能大于第三边。

2.2-2 到 2.2-5 可以说解惑了，那几个度量如果是这样定义出来的那就合理了，涉及的几个范数如果以向量长度的视角来看那就很自然了。做欧几里得空间的问题时，向量和点是没分别的，现在当然也是，只是这本书的叙事比较凑合，容易给读者造成误会。

所以完备化的叙述就放在之后，2.2-8 和 2.2-9 提供的视角更加欧几里得风格了哈哈。

== 习题

1. $d(0,x)=d(x,0)=norm(x)$
2. 显然
3. 如上一节我所述
4. 反之则会在 $arrow(0)$ 出有不必要的多值性，也会违反 $N_4$；$N_3 -> norm(-x)=norm(x)$，将 $x=x,y=-x$ 代入 $N_4$ 可得 $0<=2norm(x)$
5. 可以用 $x=x,y=-y,z=0$ 从度量的三角不等式推出来，注意 $norm(x)=norm(-x)$
6. 无聊，略
7. 可以用 5. 讲的方法做出来
8. 正好覆盖 6。第二个如 7. 所述；第一个显然；最后一个也显然。
9. 显然。注意 $abs(x(t)+y(t))<=abs(x(t))+abs(y(t))$
10. 视错觉下很容易把 $norm(x)_2$ 看成不圆，实际很圆哈哈。
11. 注意 $alpha x+(1-alpha)y=y+alpha(x-y)$，所以实际上图 2-6 就是凸集这个概念真正想表达的。至于这道题的证明比较显然，要用到 $N_3$ 和 $N_4$.
12. 前三个 N 其实都满足，第四个可以找反例，比如 $(1,1)$，我感觉是在引发我们对单位圆凸性和三角不等式关联的兴趣。
13. 首先如果想 2.2.1 那样从范数导出离散度量，那么这个范数的值域是 ${0,1}$，但进一步推理可以发现这个度量只能对 $d(x,0)=norm(x-0)$ 的情况输出 $1$，违反了离散度量的定义。
14. 实际上在说 $norm(x-y)+1=overline(norm(x-y))$，也就是 $overline(norm(x))=norm(x)+1$，然而这并不能称为一个范数，比如 $N_2$ 就不满足。
15. 相当于翻译一下了。毕竟 $m in M$ 都可以翻译成 $m=x-y$

嗯哼我居然忘了平移不变性的两个公式。



#bibliography("ref.bib")