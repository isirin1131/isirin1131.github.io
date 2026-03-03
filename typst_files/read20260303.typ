#import "@preview/basic-document-props:0.1.0": simple-page
#show: simple-page.with("刌刈", "isirin1131@outlook.com", middle-text: "每日读书笔记", date: true, numbering: true, supress-mail-link: true)

#set text(font: ("Sarasa Fixed Slab SC"), lang:("zh"))

#show math.equation: set text(font: "Neo Euler")

= 泛函导论 Erwin 

== 1.1

距离函数比集合重要，因为距离函数描绘空间中点的相对关系。

=== 习题

1. 排列组合 x,y,z 的大小顺序即可消去距离函数的绝对值符号
2. 不符合三角不等式。
3. 考虑 $sqrt(3)<=sqrt(1)+sqrt(1)+sqrt(1)$，详细证明略。2,3这两道题都聚焦在 $x<=z<=y$ 的情形。
4. 不会。
5. $M_1 -> k>=0$，$M_4 -> k >= 0$
6. [#text(red)[❌]]$d(x,y)<= sup x + sup y <= d(x,z)+d(z,y) <= sup x + 2sup z + sup y$
7. 函数在限定定义域后的表达能力塌缩。$d(x,y)=limits(max)_(j in NN) [x_j xor y_j]$
8. $|x(t)-z(t)|+|z(t)-y(t)|>=|x(t)-y(t)|$ 永远成立
9. 略
10. d = xor + bitcount，$x xor z xor z xor y = x xor y$，考虑 bitcount A + bitcount B >= bitcount (A xor B) 即可。
11. 按公式分解即可，略
12. 枚举绝对值的正负号，注意 d 的交换不变性，略。
13. 同上。
14. 重点是 $M_3$，把给的公式的 $z$ 换成 $x$ 或者 $y$，得到 $d(x,y)<=d(y,x) and d(y,x)<=d(x,y)$
15. 考虑 $d(x,y) <= d(x,z) + d(z,y)$ 若成立，则 $d(x,y)-d(y,z) <= d(x,z) <= d(x,y) + d(y,z)$，但若 $d(y,z) < 0$ 此表达式便不成立。

看了书自带的答案。

3用了一个没见过的不等式，4有点敷衍，只是描述了一个族。6 的比较有启发，我做的时候想当然地错了；7 确实更进一步了，我没深入想。15 更优雅。

大多是热身题，没啥观点。下一节看着有点吓人。


= #link("https://www.qstheory.cn/20260228/52496708255342c8a7b1f77665693635/c.html")[#text(blue)[着力破解周期性、结构性和体制性问题]]

比较高屋建瓴+抽象，但也很全面。除了坚持改革、坚持开放和坚持宏观调控外，还有提振内需的大方向。

值得注意的是把十五五定位成了一个重要时间节点，想把这五年搞成里程碑。虽然又要抗压又要啃硬骨头，不过还是期待政府的工作成果。