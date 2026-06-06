#import "../style.typ": *

== Phoenix Retrieval，先从海量内容里捞一小桶

排序模型再强，也不能对全站每一条内容逐条打分。召回阶段的任务是把“几百万甚至更多候选”缩小成“几百或几千个值得精排的候选”。本项目里，Phoenix Retrieval 用 two-tower 思路做这件事。

=== 召回要解决什么问题

想象你要给用户推荐帖子。最直接的方法是：

```python
for post in all_posts:
    score = expensive_model(user, post)
return top_k(score)
```

这在小 demo 里成立，在线上系统里不可用。候选太多，模型太贵，延迟太紧。召回阶段因此追求一个不同目标：不要一开始就精确排序，只要快速找出一批“可能相关”的内容。

#beginner("召回和排序的分工", [
  召回像先从图书馆里找到 200 本可能相关的书；排序像再认真读摘要、目录和上下文，把最适合你的 20 本排到前面。
])

=== Two-tower 的基本形状

Phoenix Retrieval 的关键文件是 #codepath("phoenix/recsys_retrieval_model.py")。里面的 `PhoenixRetrievalModel` 把系统拆成两座塔：

#table(
  columns: (1.4fr, 2.5fr, 2.4fr),
  inset: 6pt,
  stroke: 0.5pt + line,
  [塔], [输入], [输出],
  [User Tower], [用户 hash、历史行为、product surface 等], [用户向量 `u`],
  [Candidate Tower], [帖子和作者 embedding], [候选向量 `v`],
)

两边输出都被放到同一个向量空间里。召回时只需要算相似度：

`score(user, item) = dot(user_vector, item_vector)`

当向量都做过归一化，点积越大，方向越接近，系统就越认为这个候选和用户当前兴趣相近。

=== 为什么候选塔可以提前算

two-tower 的工程优势在于：候选塔只依赖帖子和作者，不依赖某个具体用户。于是候选内容的向量可以提前离线或准实时算好，放进向量索引里。在线请求来时，只需要：

1. 用 User Tower 算当前用户向量。
2. 在候选向量索引里查 top K。
3. 把这些候选交给 ranking 阶段。

这就是召回能处理大规模语料的核心原因。它把“每个用户对每个帖子跑大模型”变成“用户向量查索引”。

=== 读 `CandidateTower`

`CandidateTower` 在 #codepath("phoenix/recsys_retrieval_model.py") 中。搜索类名即可定位。它接收 post + author 的 embedding，并投影到共享空间：

```python
hidden = jnp.dot(post_author_embedding.astype(proj_1.dtype), proj_1)
hidden = jax.nn.silu(hidden)
candidate_embeddings = jnp.dot(hidden.astype(proj_2.dtype), proj_2)

candidate_norm_sq = jnp.sum(candidate_embeddings**2, axis=-1, keepdims=True)
candidate_norm = jnp.sqrt(jnp.maximum(candidate_norm_sq, EPS))
candidate_representation = candidate_embeddings / candidate_norm
```

这段代码可以分成三层理解：

- `post_author_embedding`：把内容和作者信息拼起来。
- 两层投影加激活：把原始 embedding 变成适合检索的向量。
- L2 normalization：把向量长度归一，方便用点积比较方向相似度。

#caution("不要把向量检索当成最终答案", [
  召回分数只负责“先捞出来”。它通常不包含所有业务约束，也不适合直接决定最终顺序。最终展示还要经过 hydration、filter、ranking、selector 和可见性检查。
])

=== Retrieval sequence 和 scoring sequence

在 #codepath("home-mixer/candidate_pipeline/phoenix_candidate_pipeline.rs") 中，query hydrator 里同时出现了 `ScoringSequenceQueryHydrator` 和 `RetrievalSequenceQueryHydrator`。这说明召回和排序可能使用不同形态的用户历史。

新手可以这样理解：

- retrieval sequence 更关心“用什么历史快速表达用户兴趣，以便找候选”。
- scoring sequence 更关心“精排模型要看哪些上下文，以便预测多种行为”。

它们都来自用户行为，但服务于不同模型阶段。

=== 召回阶段的常见误区

误区一：召回只要越多越好。实际不是。召回太少会漏掉好内容；召回太多会拖慢 hydration 和 ranking，还会把噪声交给后面。

误区二：召回模型越复杂越好。召回阶段通常更重视吞吐、索引效率和稳定性；复杂模型如果不能高效预计算候选向量，可能线上不可用。

误区三：召回能替代过滤。不能。召回模型只负责相关性，屏蔽、静音、可见性、安全、重复内容等仍然要由后续阶段处理。

=== 本节练习

1. 打开 #codepath("phoenix/recsys_retrieval_model.py")，找到 `CandidateTower`，标出“拼接、投影、归一化”三步。
2. 在 #codepath("home-mixer/sources/phoenix_source.rs") 里观察 Phoenix source 怎样调用 retrieval client。
3. 用一句话解释：为什么召回阶段适合用 ANN 或向量索引，而不是对所有候选逐个精排。
