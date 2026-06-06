#import "../style.typ": *

== 训练和评估，线上目标怎样变成模型

本项目主要提供推理和服务代码，但 README 和 Phoenix demo 已经给出训练闭环的入口线索。本节从新手角度解释：线上行为如何变成训练目标，模型如何评估，为什么离线指标不能替代线上实验。

=== 样本从哪里来

训练样本通常来自：

- 展示日志：用户看到了哪些候选。
- 行为日志：用户 favorite、reply、repost、click、dwell、not interested 等。
- 候选上下文：当时的 user history、candidate、position、surface。
- 内容理解结果：安全标签、topic、embedding、摘要。

没有展示日志，就很难知道“用户没有点”的候选是什么。没有行为日志，就无法定义正负反馈。没有上下文，就无法复现模型当时应该看到的信息。

=== Label 的复杂性

推荐系统的 label 不只是 0/1：

#table(
  columns: (1.3fr, 3.2fr),
  inset: 5pt,
  stroke: 0.5pt + line,
  [行为], [建模含义],
  [favorite], [明确正反馈，但可能偏轻量。],
  [reply], [强互动，可能代表兴趣，也可能代表争议。],
  [repost/quote], [传播意愿。],
  [click/profile click], [探索行为。],
  [dwell], [停留信号，常作为连续值或弱正反馈。],
  [not interested], [明确负反馈。],
  [block/mute/report], [强负反馈和安全信号。],
)

多行为模型的意义就是同时学习这些目标，而不是压成一个模糊的 relevance。

=== 离线评估

离线评估可以看：

- AUC、log loss、calibration。
- top K recall。
- 多行为预测质量。
- 分桶指标，例如新用户、重度用户、视频、话题请求。
- 负反馈预测能力。

离线评估的优点是快、便宜、可重复。缺点是它依赖历史数据分布，无法完全预测线上用户对新排序策略的反应。

=== 线上评估

线上 A/B 实验需要看：

- 互动和留存。
- 负反馈和安全事件。
- 内容多样性。
- 作者生态。
- 延迟和错误率。
- 日志完整性。

线上实验更接近真实目标，但成本高、周期长、需要防护。推荐系统的成熟度体现在：能把离线评估、线上实验和系统指标连起来决策。

=== 训练和服务的一致性

常见问题是训练和服务不一致：

- 训练用的 feature 和线上 query hydration 字段不同。
- 训练样本里的 action 定义和线上 scorer 权重不一致。
- 训练时没有模拟 candidate isolation。
- 线上 hash 参数和导出 config 不一致。
- 训练数据缺少某类请求或某类用户。

本地 `run_pipeline.py` 通过加载 config、hash 参数、embedding table 和 checkpoint，帮助你理解推理一致性的重要性。

=== 评估新模型的检查清单

```text
模型版本：
训练数据时间窗：
行为 label 定义：
hash/config 是否匹配：
离线指标：
分桶指标：
负反馈指标：
推理延迟：
内存和吞吐：
线上实验分桶：
回滚方案：
```

=== 本节练习

1. 选择 favorite、reply、dwell、not interested 四个 label，说明它们可能冲突的场景。
2. 解释为什么离线 AUC 提升不保证线上体验提升。
3. 设计一个新 ranker 上线前的最小评估表。

