#import "@preview/basic-document-props:0.1.0": simple-page
#show: simple-page.with("刌刈", "isirin1131@outlook.com", middle-text: "每日读书笔记", date: true, numbering: true, supress-mail-link: true)

#set text(font: ("Sarasa Fixed Slab SC"), lang:("zh"))

#show math.equation: set text(font: "Neo Euler")

= 《现实不似你所见》

信息密度非常低的一本科普书。

通过布朗运动佐证原子论，驳斥物质无限可分。

牛顿的工作 balabala……但是当真如此吗？

用场的振动描述光。

受不了这语言风格了，弃之。

= VAE 教程 @doersch2021tutorialvariationalautoencoders

VAE 在 13 年的那个原论文对外行来说太过晦涩，而这篇就非常友好了，它至少告诉你问题的源流和脉络。虽然这篇也挺老，一上来就引用 AlexNet，但从 2016 年第一次放出到 2021 年还更新到 V3 版本，也算间接证明含金量了。

隐变量或者说潜变量的假设是用来定义一个两步走的高维数据（比如图片，音频）采样方式，首先采样隐变量 $z in cal(Z)$，再用模型 $f(z,theta)$ 生成高维数据，其中 $theta$ 是模型参数，而 $f$ 定义了一种确定性的生成过程。

$P(X | z; theta)$ 是在现有模型参数 $theta$ 下，采样到的潜变量为 $z$ 时，高维数据 $X$ 的分布。这里的高斯分布函数 $cal(N)$ 是个高维分布，它假设 $P(X | z; theta)$ 是由一堆相互独立的 一维高斯分布函数组成的。

这里的优化目标 $P(X)$ 实际上写的有点语焉不详。$z$ 也能从正态分布中采样后经由复杂函数的后处理服从各种分布的假设，无从验证暂时先记下。

KL 散度完全是个信息论的公式，先不要尝试证明它。

那个 VAE 的核心公式，主要是在说训练 P 和 Q 使得能把 $X$ 编码成 $z$ 再解码成 $X$ 就相当于在优化论文之前提出的积分优化目标了。图 4 佐证了这种说法。

后面的训练细节读的有点脑壳疼，太抽象了。论文的剩余部分也是附录性质，就不继续读了。






#bibliography("ref.bib")