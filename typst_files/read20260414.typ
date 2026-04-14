#import "@preview/basic-document-props:0.1.0": simple-page
#show: simple-page.with("刌刈", "isirin1131@outlook.com", middle-text: "每日读书笔记", date: true, numbering: true, supress-mail-link: true)

#set text(font: ("Sarasa Fixed Slab SC"), lang:("zh"))

#show math.equation: set text(font: "Neo Euler")

= 泛函导论 Erwin

之前读那个线性代数应该这样学也是强调有限维的比较重要。

== 2.4

粗略看了一下，这章应该是要刷新我的世界观，之前的都太无聊了。

2.4-1 翻译似乎有问题？原定理的表述是存在一个固定的 $c$，它只依赖 ${x_1,dots,x_n}$。这时候还得上 AI，经过一通提问，这里的阅读顺序应该先上 2.4-4，顺便回顾一下 #sym.section 1.3 的拓扑概念。另外还需要补充一个 $cal(l_1)$ 范数，也即对一组 base ${x}_n$ 来说，表示一个向量要用 $sum _(1<=i<=n)alpha_i x_i$，那么这个向量在这个 base 下的坐标表示就是 $(alpha_1,dots,alpha_n)$，同时它的 $cal(l_1)$ 范数就是 $sum_i abs(alpha_i)$

补充完 $cal(l_1)$ 范数之后应该立即看 2.4-4，首先不难发现 (2.4.3) 的变体是 $1/b norm(x)<=norm(x)_0<=1/a norm(x)$，这个是对称性，传递性也很好验证，自反性更不必说，所以确实是个等价关系。

等价范数定义了相同的拓扑这件事更应该好好说道一下，

=== 习题

== 2.5

=== 习题



#bibliography("ref.bib")