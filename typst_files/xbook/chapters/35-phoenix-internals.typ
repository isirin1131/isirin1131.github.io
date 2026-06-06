#import "../style.typ": *

== Phoenix 内部，embedding、mask 和输出头

前面讲了 Phoenix 的 retrieval/ranking 分工。本节更细看模型内部的几个关键概念：hash embedding、输入拼接、attention mask、输出头。

=== Hash embedding

Phoenix 不直接为每个 user id、tweet id、author id 建独立 embedding。它使用多组 hash，把实体映射到 embedding table。好处是：

- 控制 embedding table 大小。
- 处理大量稀疏 id。
- 允许导出固定大小的表。

代价是 hash collision。多个实体可能共享 bucket。多 hash 和模型训练可以缓解，但不能完全消除。

=== User、history、candidate 三段输入

`PhoenixModel.build_inputs` 把三段拼起来：

```text
[ user ][ history actions ... ][ candidates ... ]
```

每一段都来自不同 reduce 函数：

- `block_user_reduce`
- `block_history_reduce`
- `block_candidate_reduce`

这些函数把多个 hash embedding、行为 embedding、product surface、时间 bucket 等压成统一维度。

=== Product surface

`history_product_surface` 和 `candidate_product_surface` 告诉模型行为或候选发生在哪个产品场景。相同用户行为在不同 surface 上含义可能不同，例如 Home、搜索、视频页、通知入口。

新手可以把 product surface 理解成“上下文标签”，让模型知道这次预测发生在哪个产品场景。

=== Post age bucket

排序模型会计算候选年龄 bucket：

```python
post_age_minutes = (impr_ts_sec - post_creation_ts_sec) // 60
bucket = (post_age_minutes // granularity_mins) + 1
```

帖子年龄影响推荐。新鲜内容和旧内容的互动模式不同。用 bucket 而不是原始秒数，可以让模型更稳定地学习时间段效果。

=== Candidate isolation mask

`make_recsys_attn_mask` 是 Phoenix ranking 最关键的工程设计之一。它让候选能看用户和历史，也能看自己，但不能看其他候选。

```text
candidate_i -> user/history: allowed
candidate_i -> candidate_i: allowed
candidate_i -> candidate_j: blocked
```

这样同一候选的分数不会因为批次里放了哪些其他候选而变化太大。

=== 输出头

排序模型输出两类结果：

- discrete logits：多种离散行为，例如 favorite、reply、repost。
- continuous preds：连续行为，例如 dwell time。

代码上是取 candidate 位置的 transformer 输出，再乘以 unembedding matrix：

```python
candidate_embeddings = out_embeddings[:, candidate_start_offset:, :]
logits = jnp.dot(candidate_embeddings, unembeddings)
```

这和语言模型的“hidden state -> vocab logits”很像，只是这里的 vocab 换成了 action types。

=== Retrieval user tower 和 ranking 的关系

Retrieval user tower 使用类似 transformer 结构来编码用户历史，但目标不同：它输出 user representation，用来和候选向量点积。Ranking 则输出每个候选的行为预测。

可以这样记：

- Retrieval 输出一个用户向量。
- Ranking 输出每个候选的一组行为预测。

=== 本节练习

1. 解释为什么 candidate isolation 能提高排序分数稳定性。
2. 找出 `RecsysBatch` 中哪些字段属于 user、history、candidate。
3. 说明 post age bucket 为什么比直接使用秒数更适合作为模型输入。
4. 对比 retrieval 输出和 ranking 输出的形状和用途。

