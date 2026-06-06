#import "../style.typ": *

== 调试场景题库

这一节提供更多场景题。每个场景都要求你用本书的方法定位问题，而不是凭直觉猜。

=== 场景 1：OON 内容突然消失

现象：For You 里几乎全是关注网络内容。

优先检查：

- `PhoenixSource::enable` 是否为 false。
- `retrieval_sequence` 是否缺失。
- `PhoenixRetrievalInferenceClusterId` 是否变化。
- `PhoenixMaxResults` 是否被调小。
- `in_network_only` 是否被 viewer data 或请求字段置 true。
- OON weight 是否被压得太低。

结论格式：

```text
供给层：PhoenixSource 返回量
排序层：OON 候选分数
选择层：OON 入选数量
最终占比：selected 中 OON ratio
```

=== 场景 2：视频内容突然变少

检查：

- `exclude_videos` 是否为 true。
- `VideoDurationCandidateHydrator` 是否失败。
- `VideoFilter` 移除率。
- `vqv_weight` 和视频时长阈值。
- 视频候选 source 返回量。

这类问题可能发生在 source、hydrator、filter、scorer 任一层。

=== 场景 3：缓存命中后质量下降

检查：

- `has_cached_posts` 是否 true。
- cached posts 数量是否刚好超过阈值。
- 缓存 TTL 是否过长。
- cached candidates 是否经过必要 post-selection filter。
- served history 是否仍然生效。
- 缓存写入是否包含 non_selected 高分候选。

缓存路径要同时看延迟收益和新鲜度损失。

=== 场景 4：新用户结果空

检查：

- followed_user_ids 数量。
- retrieval/scoring sequence 长度。
- new user cluster 是否启用。
- topic retrieval 是否有 topic ids。
- Thunder 是否有关注网络候选。
- cached path 是否误启用。

新用户问题通常需要 fallback source 和特殊权重。

=== 场景 5：负反馈增加

检查：

- not_interested/block/mute/report 权重。
- Phoenix 负反馈预测分布。
- 某个 source 是否引入高风险候选。
- VFFilter 和 safety label 是否异常。
- OON weight 是否过高。
- 广告或 prompt 插入是否改变用户体验。

负反馈问题不能只看模型，还要看供给和混排。

=== 场景 6：P99 延迟升高但平均值正常

检查：

- 哪个 stage P99 高。
- source/hydrator fan-out 是否变多。
- Redis cache miss 是否升高。
- Thunder rejected requests 是否变化。
- PhoenixScorer 是否 fallback。
- side effect 是否意外阻塞当前路径。

P99 问题通常来自尾部依赖或容量边界。

=== 场景 7：实验指标无法解释

检查：

- 分桶是否正确。
- feature switch 是否按预期命中。
- decider override 是否生效。
- 日志 side effect 是否完整。
- selected/non_selected 是否都被记录。
- 实验组和对照组是否走了相同缓存策略。

实验异常经常是数据链路问题，不一定是策略本身。

=== 本节练习

选择三个场景，写出 10 步以内的排查计划，并标明每一步需要看的文件或指标。

