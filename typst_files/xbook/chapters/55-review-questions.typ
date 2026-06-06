#import "../style.typ": *

== 复习题

这一节提供一组短问题。建议读者不看答案，先口头回答，再回到代码验证。

=== 架构

1. Home Mixer 和 Phoenix 的边界是什么？
2. 为什么 For You 有内外两层 pipeline？
3. `PostCandidate` 和 `FeedItem` 的区别是什么？
4. Thunder 和 Phoenix Retrieval 分别解决什么候选问题？

=== Pipeline

1. `CandidatePipeline::execute` 的阶段顺序是什么？
2. 哪些阶段并行，哪些阶段顺序？
3. 为什么 filter 不能并行地独立删除候选？
4. side effect 为什么放在最后？

=== Query

1. `ScoredPostsQuery` 中哪些字段来自原始请求？
2. 哪些字段由 query hydrator 补齐？
3. `params` 和 `decider` 分别控制什么？
4. `has_cached_posts` 为什么是路径切换字段？

=== Candidate

1. 一个 source 最少应该写哪些字段？
2. `author_id=0` 在 CoreDataHydrationFilter 中代表什么？
3. `get_original_tweet_id` 为什么必要？
4. `score=None` 在 selector 中如何处理？

=== Phoenix

1. Retrieval 为什么用 two-tower？
2. Ranking 为什么需要 candidate isolation？
3. 多行为预测比单一 relevance 有什么优势？
4. 本地 `run_pipeline.py` 和线上 Home Mixer 差异在哪里？

=== 生产

1. source 失败时 pipeline 如何继续？
2. query hydrator 失败有什么风险？
3. side effect 失败为什么影响未来？
4. 你会如何排查 final result size 突降？

=== 开放题

1. 如果要新增一个 source，你会先写哪些指标？
2. 如果负反馈上升，你会从哪三层查？
3. 如果缓存命中后用户看到重复内容，可能原因有哪些？
4. 如果 P99 延迟升高但 P50 不变，说明什么？

