#import "@preview/basic-document-props:0.1.0": simple-page
#show: simple-page.with("刌刈", "isirin1131@outlook.com", middle-text: "", date: true, numbering: true, supress-mail-link: true)

#set text(font: ("Sarasa Fixed Slab SC"), lang:("zh"))

学术界论文的坏习惯是模糊公式和隐藏细节，因此年代过早的东西不是很能信任。所以我直接放弃复现 VAE、GAN 等老古董，从 ViT 开始。

#outline()

== 《Attention is all you need》

我又回来了，《Attention is all you need》，这次带着更弔的翻译器。

这论文快十年了，稍微看一下就行了。

模型架构就是 encoder-decoder，其余部分的老古董价值不大，具体地，读 3.2.1 和 3.2.3。

关于注意力机制，我的建议是，先不要在 QKV 上浪费时间，如果可以接受暂时不了解前馈层 `Linear(ReLU(Linear))` 的全部行为，应该就也能接受对 Attention 的不了解。

更不要在那些不知所谓的科普文章上浪费时间，它们能提供的信息并不多于论文本身。

== 太晚了，明天看吧。

跟活成力工的老妈聊太久了。也算是个是奇人了，只听闻男人当力工，哪有女人当力工的呢？但她就是当了十年大夯工。
