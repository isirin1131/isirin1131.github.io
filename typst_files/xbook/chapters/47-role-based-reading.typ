#import "../style.typ": *

== 按角色选择阅读路径

不同读者关注点不同。推荐算法新手、后端工程师、机器学习工程师、数据分析师、产品经理读这本书时，不需要完全同一条路线。

=== 后端新手

推荐路线：

1. 前言和项目地图。
2. 服务化推荐的分布式最小模型。
3. Candidate Pipeline。
4. Query hydration、sources、hydrators、filters。
5. 错误处理和降级。
6. 生产 runbook。

重点问题：

- 哪些调用是并行的？
- 哪些阶段必须顺序？
- 失败时系统如何继续？
- 如何通过指标定位问题？

先不要深挖 Phoenix 数学。你需要先掌握服务链路。

=== 推荐算法新手

推荐路线：

1. 项目地图。
2. Phoenix Retrieval。
3. Phoenix Ranking。
4. Phoenix 内部。
5. 训练和评估。
6. 参数和实验。
7. 数据闭环。

重点问题：

- 召回和排序为什么分开？
- 多行为预测如何变成最终分？
- 训练 label 从哪里来？
- 离线指标和线上实验有什么差异？

=== 机器学习工程师

推荐路线：

1. Phoenix 本地实战。
2. Python/JAX 读法。
3. Phoenix 内部。
4. Retrieval/Ranking 实验课。
5. Scorer 深度导读。
6. 训练和评估。

重点问题：

- 模型输入 shape 是否正确？
- candidate isolation 是否被保持？
- artifacts、config、hash 参数是否一致？
- 模型输出如何被业务权重使用？

=== Feed 产品或策略同学

推荐路线：

1. 项目地图。
2. Scoring 和 Selection。
3. Selector 和混排。
4. 参数、开关和实验。
5. 数据闭环。
6. 生产 runbook。

重点问题：

- 分数代表什么产品目标？
- 负反馈如何进入目标函数？
- 广告和非帖子 item 如何插入？
- 实验应该看哪些指标？

=== 数据分析师

推荐路线：

1. Side effects 和观测性。
2. 数据闭环。
3. 训练和评估。
4. 观测性 Dashboard。
5. 生产 runbook。

重点问题：

- 展示日志在哪里产生？
- selected 和 non_selected 有什么区别？
- 训练样本可能有什么偏差？
- 指标分桶应该如何设计？

=== 安全和可见性相关读者

推荐路线：

1. Filtering。
2. Filter 深度导读。
3. 安全和可见性。
4. Grox 深入。
5. 生产 runbook。

重点问题：

- 哪些内容是硬约束？
- visibility_reason 如何被消费？
- None/false 默认值是否安全？
- 内容理解延迟如何影响线上过滤？

=== 读者自测

如果你能回答下面问题，就说明入门主线已经掌握：

- 为什么 source 可以并行，而 filter 通常顺序？
- cached posts true 时 pipeline 发生了什么？
- Phoenix Retrieval 和 Phoenix Ranking 的输入输出分别是什么？
- 一个候选从 source 到 response 经过哪些字段变化？
- side effect 失败为什么可能影响未来训练？
