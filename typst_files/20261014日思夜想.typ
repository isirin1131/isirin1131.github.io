#import "@preview/basic-document-props:0.1.0": simple-page
#show: simple-page.with("刌刈", "isirin1131@outlook.com", middle-text: "", date: true, numbering: true, supress-mail-link: true)

#set text(font: ("Sarasa Fixed Slab SC"), lang:("zh"))

看 Gemini 4 写文能力有点震撼，就开了 Google AI Pro，额度有点多。

眩晕瘫坐？眩晕瘫坐！

Cyly 决定不采用任何函数式特性，前些天关于闭包的思考也应作废，闭包这个特性带出了无数问题。

类是图灵完备的。因此 OOP 的类模型、原型模型采用的继承、Override 等范式实际上是 “程序修改程序” 这件事的 fallback。因为前 agent 时代在运行时按字符修改程序实在是太过超前了。

Cyly 将成为更彻底的过程式语言。

#line()

在这上面打转了一个下午：

```C
int a = 1, char c = 'c', double b = 3.14 {
  print a, b, c;
}
```

我似乎犯了一个方向性问题。本来是想做更纯粹的过程式语言，但做着做着就想做一种完全不同的范式了。还是 C 这一派比较贴近汇编，我决定不再想着改变编程范式，而是把目光放在用一个轻量如 C 的编译型过程式语言一次性打包并发、异步甚至异构计算、GPU 并行计算等热门领域的代码编写模式。

这些可都是大领域，不能贪多嚼不烂。

那么就从单核语言+适配现代 OS 对内存模型开始吧。

至少 Cyly 得能让我自己选择用它而不是 C。
