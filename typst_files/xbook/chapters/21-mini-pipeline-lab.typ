#import "../style.typ": *

== 手写一个最小推荐流水线

读完真实系统后，最好自己写一个小版本。这个练习不追求性能，只追求把 source、hydrator、filter、scorer、selector 的边界刻进脑子里。

=== 目标

实现一个内存版 feed：

- 两个 source：关注作者 posts、全局热门 posts。
- 一个 query hydrator：补关注列表。
- 一个 candidate hydrator：补文本和作者名。
- 两个 filter：去重、屏蔽作者。
- 一个 scorer：按兴趣词和新鲜度打分。
- 一个 selector：取 top K。
- 一个 side effect：打印 served ids。

这个小系统可以用 Python、Rust 或 TypeScript 写。语言不重要，阶段边界重要。

=== 数据模型

```text
Query:
  user_id
  followed_author_ids
  blocked_author_ids
  interests

Candidate:
  post_id
  author_id
  text
  created_at
  source
  score
```

source 初始只返回 `post_id`、`author_id`、`source`。hydrator 再补 `text` 和 `created_at`。这样你能练习“候选先瘦后胖”的思路。

=== 伪代码

```python
async def execute(query):
    query = await hydrate_query(query)

    source_results = await gather(
        followed_source(query),
        trending_source(query),
    )
    candidates = flatten(source_results)

    candidates = await hydrate_candidates(query, candidates)

    kept, removed = drop_duplicates(query, candidates)
    kept, removed2 = author_block_filter(query, kept)
    removed += removed2

    scored = await score(query, kept)
    selected = top_k(scored, k=20)

    create_task(write_served_ids(query, selected))
    return selected
```

这个伪代码就是 `CandidatePipeline::execute` 的缩小版。

=== 验证用例

至少写五个测试：

1. 两个 source 返回同一 post，最终只保留一个。
2. 被屏蔽作者的 post 被移除。
3. 包含兴趣词的 post 分数更高。
4. source 之一失败时，另一个 source 的候选仍然返回。
5. 没有 score 的候选不会排在已打分候选前面。

这些测试对应真实系统中的关键不变量。

=== 扩展任务

完成最小版后，再加三个功能：

- 缓存 hydrator：post metadata 命中缓存时不访问 client。
- 过滤率统计：记录每个 filter 移除多少候选。
- side effect 失败计数：即使不阻塞响应，也要记录错误。

这三个扩展能帮你理解为什么真实系统需要缓存、观测性和后台任务。

=== 对照真实代码

#table(
  columns: (1.5fr, 2.8fr),
  inset: 5pt,
  stroke: 0.5pt + line,
  [小实验], [真实项目对应],
  [followed_source], [`ThunderSource`],
  [trending_source], [`PhoenixSource` 或其他 source],
  [metadata_hydrator], [`CoreDataCandidateHydrator`],
  [drop_duplicates], [`DropDuplicatesFilter`],
  [author_block_filter], [`AuthorSocialgraphFilter`],
  [score], [`PhoenixScorer` + `RankingScorer`],
  [top_k], [`TopKScoreSelector`],
  [write_served_ids], [`ServedCandidatesKafkaSideEffect` 或 seen ids side effect],
)

=== 本节练习

1. 用你熟悉的语言实现这个最小 pipeline。
2. 给每个阶段打印输入数量和输出数量。
3. 故意让一个 source 抛错，验证系统是否仍然返回另一个 source 的候选。
4. 把 hydrator 改成随机少返回一个结果，观察为什么真实框架要做长度检查。

