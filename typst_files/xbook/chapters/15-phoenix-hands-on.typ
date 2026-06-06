#import "../style.typ": *

== Phoenix 本地实战，从 artifacts 跑完整链路

前面讲 Phoenix retrieval 和 ranking 的模型结构。这一节看 #codepath("phoenix/run_pipeline.py")，它是本仓库最适合作为本地实验入口的文件，因为它把 retrieval -> ranking 串成一个可运行脚本。

=== 这个脚本解决什么

`run_pipeline.py` 的 docstring 写得很清楚：它加载导出的 checkpoint、预计算 corpus、用户行为序列，然后执行：

1. Retrieval：编码用户历史，与 corpus 向量做点积，取 top K。
2. Ranking：对 top K 候选运行 engagement model。
3. Display：打印按加权 engagement 排序的结果。

这和线上系统的关系是：它不包含 Home Mixer 的所有 hydrator、filter、side effect，但能帮助你理解 Phoenix 模型本身如何从用户历史走到候选排名。

=== artifacts 结构

脚本期望的目录大致是：

```text
artifacts/
  retrieval/
    model_params.npz
    embedding_tables.npz
    config.json
  ranker/
    model_params.npz
    embedding_tables.npz
    config.json
  sports_corpus.npz
  example_sequence.json
```

这些文件分别对应模型参数、embedding table、模型 config、候选 corpus 和用户行为序列。

新手要注意：本地 pipeline 不是训练脚本，而是 inference demo。它用已经导出的参数和 corpus 跑一遍前向推理。

=== hash 函数

`build_hash_functions` 根据 config 里的 hash 参数构造 user/item/author hash。模型不直接拿原始 id 做 embedding lookup，而是把 id 映射到 hash bucket。

这有两个意义：

- embedding table 大小可控。
- 不同实体类型可以共享一个统一 embedding table 的不同区间。

代码中 `build_unified_emb_table` 把 user、item、author 三张表拼到一个大表里，并预留 padding 区间。

=== 加载模型

`load_model_params` 在 #codepath("phoenix/runners.py") 中。它把 `.npz` 里的 key 拆成 Haiku 参数树：

```python
parts = key.split("/")
module_path = "/".join(parts[:-1])
param_name = parts[-1]
params.setdefault(module_path, {})[param_name] = jnp.array(data[key])
```

`load_embedding_table` 则读取 embedding table。理解这两步后，你就知道 JAX/Haiku 模型推理需要两类东西：

- params：神经网络参数。
- embeddings：输入 id 查表后的向量。

=== 构造用户历史

脚本从 `example_sequence.json` 中读取：

- `user_id`
- `history`
- 每条历史里的 `post_id`
- `author_id`
- `actions`

然后填入固定长度数组：

```python
history_post_ids = np.zeros(hist_len, dtype=np.uint64)
history_author_ids = np.zeros(hist_len, dtype=np.uint64)
history_actions = np.zeros((hist_len, num_actions), dtype=np.float32)
```

真实系统中的 query hydrator 做的事情更复杂，但概念相同：把用户历史整理成模型能读的张量。

=== Retrieval 前向

脚本构造 retrieval batch 和 embedding batch 后，调用 retrieval model 得到 `user_repr`：

```python
user_repr = ret_fn.apply(ret_params, batch, emb_batch, dummy_gn, dummy_gn)
scores = corpus_repr @ np.asarray(user_repr[0])
```

这里 `corpus_repr` 是预计算候选向量。`@` 是矩阵乘法，等价于一次性计算用户向量和所有候选向量的点积。然后通过 `argpartition` 取 top K。

这正是 two-tower 召回的工程优势：候选向量提前算好，在线只算用户向量和相似度。

=== Ranking 前向

retrieval 返回 top K 后，脚本按 `candidate_seq_len` 分批送入 ranker：

```python
for i in range(0, TOP_K, cand_len):
    ...
    out = rank_fn.apply(rank_params, rb, re)
    probs = jax.nn.sigmoid(out.logits)
```

ranker 输出 logits，脚本用 sigmoid 变成概率。然后用一个简单权重组合：

```python
weighted = fav * 1.0 + reply * 0.5 + rt * 0.3 + dwell * 0.2
```

线上 `RankingScorer` 的权重更完整，也会包含负反馈、多样性、OON 调整。本地脚本的目标是演示链路，不是复制全部线上排序策略。

=== 读输出

脚本打印：

- retrieval score
- favorite/reply/retweet/dwell/VQV 概率
- weighted score
- topic
- post URL

看输出时，不要只盯最终 rank。你应该比较 retrieval score 和 ranking weighted score：retrieval 认为相近的内容，ranking 不一定排最高，因为 ranking 看的是更细的多行为预测。

=== 本节练习

1. 改 `--top_k_retrieval`，观察 ranking 输入候选数量如何变化。
2. 改 `--top_k_display`，确认它只影响打印数量，不影响模型推理。
3. 在本地权重公式中加入 reply 或 dwell 的更高权重，观察排序会偏向哪类候选。
4. 对比本地脚本和 `PhoenixSource` + `PhoenixScorer`：一个是离线 demo，一个是线上服务调用。

