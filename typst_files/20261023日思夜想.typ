#import "@preview/basic-document-props:0.1.0": simple-page
#show: simple-page.with("刌刈", "isirin1131@outlook.com", middle-text: "", date: true, numbering: true, supress-mail-link: true)

#set text(font: ("Sarasa Fixed Slab SC"), lang:("zh"))

#show link: set text(fill: blue)

== 折腾

美西小鸡超乎想象！CF 都不弹盾了。续了一个季度的静待黑五，看看能不能尝尝 dmit 的，实在不行就留这家的，毕竟延迟可以接受，重要的是 ip 干净，还带俩家宽。

折腾 yubikey 的开源替代，还是 picokey 这种深得我心啊，可惜原仓库闭源了，开源社区转向自己维护。而 pico-forge 的 RP2350 版本在 RS-key 这个项目，感觉结合这个，再参考一下 canokey 之类的做一个自己的分支会比较好。

Geeker！

总之，板子选型就用微雪家的 RP2350-Zero-CM，也就是(Type-)CM(ale)，母口是需要额外的线的，type-C 可以兼容手机，故 CM 型号是个甜点。

微雪比较新的那个一公一母也可以，但 Zero 有 #link("https://makerworld.com/zh/models/3269716-rp2350-zero-cm-4-piece-snap-fit-enclosure-independ")[开源外壳]，找网店打印 20 包邮。

#line(length: 100%, stroke: 0.5pt + luma(180))

== Cyly

所以 Curry-Howard 同构意味着静态类型语言的编译期类型检查器相当于一个丐版 lean，我那些折腾类型体操的群友也真心相信数学证明可以构造世界。

Cyly 该怎么做呢？我决定先读一读某大名鼎鼎的 paper。

== 《The Next 700 Programming Languages》

太臭了。不值一读。
