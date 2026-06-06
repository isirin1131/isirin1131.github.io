#import "../style.typ": *

== 生产排查 Runbook

这一节把前面的概念整理成可执行的排查手册。它不追求覆盖所有事故，只覆盖新手最常遇到的五类问题：空结果、慢请求、重复内容、排序异常、日志缺失。

=== Runbook 一：空结果

症状：某类请求返回 0 个候选，或 final result size 明显下降。

排查步骤：

1. 确认请求类型：initial/top/bottom、topic request、in_network_only、cached posts。
2. 查看 query hydration 是否成功：scoring_sequence、retrieval_sequence、followed_user_ids、blocked/muted ids。
3. 查看每个 source 的 enabled_count 和 candidate_count。
4. 对比 Thunder 和 Phoenix 的候选量，判断是 in-network 还是 OON 供给问题。
5. 查看 hydration missing/error，尤其 CoreData 和 visibility 相关字段。
6. 查看 filters 的 removed_per_filter。
7. 查看 scorer 是否写入 score。
8. 查看 selector input_count 和 selected_count。
9. 查看 post-selection filters 是否移除全部候选。
10. 对比最近参数、decider、模型 cluster、下游错误率变化。

结论要写成“候选在哪一段消失”，而不是“推荐坏了”。

=== Runbook 二：慢请求

症状：P95/P99 延迟上升，用户刷新 feed 变慢。

排查步骤：

1. 先看整体 execute latency。
2. 拆 stage：query_hydrators、sources、hydrators、filters、scorers、selector、post-selection。
3. 对慢 stage 按 component name 排序。
4. 看候选数量是否异常增长。
5. 看 cache hit/miss 是否变化。
6. 看下游错误率和重试率。
7. 看并发限制是否触发，例如 Thunder 的 rejected requests。
8. 看是否有新参数启用了额外 source 或 hydrator。

慢请求经常是“候选量变大 + 缓存命中下降 + 某个下游慢”叠加出来的。

=== Runbook 三：重复内容

症状：同一帖子、同一会话或同一作者重复出现。

排查步骤：

- 同一 tweet 重复：看 `DropDuplicatesFilter` 是否运行，tweet_id 是否正确。
- retweet 重复：看 `RetweetDeduplicationFilter` 和 retweeted_tweet_id 是否 hydrated。
- conversation 重复：看 `DedupConversationFilter` 和 conversation/ancestor 字段。
- 作者重复：看 RankingScorer 的 author diversity 参数和输出。
- 短时间重复曝光：看 served history side effects 是否成功写入。

重复问题通常跨 source、hydrator、filter、side effect。只看 selector 往往不够。

=== Runbook 四：排序看起来不合理

症状：明显低质量内容排高、负反馈内容变多、某类内容突然占比上升。

排查步骤：

1. 查看 PhoenixScorer 是否调用了预期 cluster。
2. 检查 prediction request 中用户历史和候选是否合理。
3. 抽样查看 per-action probabilities。
4. 检查 RankingScorer 权重参数是否变化。
5. 检查负反馈权重是否被错误设置为正或过小。
6. 检查 OON weight、topic weight、新用户逻辑。
7. 检查 author diversity 是否生效。
8. 检查 BlenderSelector 是否改变最终位置。

排序异常要拆成两层：模型预测是否异常，预测到最终分的组合是否异常。

=== Runbook 五：日志或训练数据缺失

症状：用户能看到内容，但曝光日志、served candidates、训练样本或实验报表缺失。

排查步骤：

1. side effect 是否被启用？看 enable 条件。
2. selected_candidates 是否为空？
3. 序列化是否失败？
4. Kafka publisher 是否报错？
5. 后台 task 是否被调度？
6. topic 或下游 consumer 是否健康？
7. 是否只有 shadow/prod/某类请求受影响？
8. 对比请求量和日志量是否成比例。

这类问题不会立刻表现为 feed 失败，但会破坏长期闭环。

=== 事故复盘模板

```text
问题摘要：
用户影响：
首次发现时间：
发现方式：
影响范围：
直接原因：
根因：
为什么监控没有更早发现：
修复动作：
回滚方案：
长期防护：
需要补充的指标：
需要补充的测试：
```

推荐系统事故复盘必须写清楚“当前请求影响”和“数据闭环影响”。后者经常被低估。

