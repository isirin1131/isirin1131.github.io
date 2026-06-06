#import "../style.typ": *

== Phoenix Ranking，给候选内容做精排

召回阶段已经把范围缩小。Ranking 阶段的任务是更认真地看用户上下文和候选内容，预测用户可能做什么，然后把这些预测变成最终排序分。

=== Ranking 输入长什么样

关键类型在 #codepath("phoenix/recsys_model.py") 的 `RecsysBatch`。它包含：

- `user_hashes`：用户标识的 hash。
- `history_post_hashes`、`history_author_hashes`：用户历史行为涉及的帖子和作者。
- `history_actions`：历史行为类型，例如喜欢、回复、转发、停留。
- `history_product_surface`：行为发生在哪个产品场景。
- `candidate_post_hashes`、`candidate_author_hashes`：本次要打分的候选。
- `candidate_product_surface`、候选时间信息、可选 IP hash 等。

这不是“把文本直接塞进模型”的接口，而是把用户、历史、候选和行为整理成张量。`RecsysEmbeddings` 则保存已经查表得到的 embedding。

=== 三段序列拼成一个模型输入

`PhoenixModel.build_inputs` 做了关键拼接；在 #codepath("phoenix/recsys_model.py") 中搜索函数名即可定位：

```python
embeddings = jnp.concatenate(
    [user_embeddings, history_embeddings, candidate_embeddings], axis=1
)
padding_mask = jnp.concatenate(
    [user_padding_mask, history_padding_mask, candidate_padding_mask], axis=1
)
candidate_start_offset = user_padding_mask.shape[1] + history_padding_mask.shape[1]
```

模型看到的序列大致是：

```text
[ User ][ History 1 ][ History 2 ] ... [ Candidate 1 ][ Candidate 2 ] ...
```

`candidate_start_offset` 记录候选从哪里开始。这个位置很重要，因为 attention mask 会用它区分“用户和历史”和“候选”。

=== Candidate isolation：候选之间不能互相偷看

在普通 transformer 里，一个 token 可能通过 attention 看到其他 token。推荐排序里，这会带来一个问题：如果 Candidate A 的分数会受 Candidate B 是否在同一批里影响，那么 A 的分数就不稳定，也不容易缓存或解释。

本项目在 #codepath("phoenix/grok.py") 的 `make_recsys_attn_mask` 里解决这个问题：

```python
causal_mask = jnp.tril(jnp.ones((1, 1, seq_len, seq_len), dtype=dtype))
attn_mask = causal_mask.at[:, :, candidate_start_offset:, candidate_start_offset:].set(0)
candidate_indices = jnp.arange(candidate_start_offset, seq_len)
attn_mask = attn_mask.at[:, :, candidate_indices, candidate_indices].set(1)
```

含义是：

```text
候选可以看：用户、历史、自己
候选不能看：其他候选
```

#tip("为什么这对线上系统重要", [
  如果候选之间能互相 attention，同一个帖子放在不同候选批次里可能得到不同分数。Candidate isolation 让每个候选的分数主要由“用户上下文 + 它自己”决定，排序更稳定。
])

=== 输出不是一个分数，而是一组行为预测

`PhoenixModel.__call__` 最后取出候选位置的输出，并映射成多种行为的 logits 和 continuous prediction：

```python
candidate_embeddings = out_embeddings[:, candidate_start_offset:, :]
logits = jnp.dot(candidate_embeddings.astype(unembeddings.dtype), unembeddings)
continuous_preds = jax.nn.sigmoid(continuous_logits).astype(self.fprop_dtype)
```

这意味着模型不会只说“相关”或“不相关”。它会预测多个行为，例如 favorite、reply、repost、click、dwell、follow author，以及一些负反馈。

真正的最终分在 Rust 侧继续计算。#codepath("home-mixer/scorers/phoenix_scorer.rs") 负责调用 Phoenix prediction client，把预测写回候选；#codepath("home-mixer/scorers/ranking_scorer.rs") 再按权重组合这些预测。

简化公式是：

`final_score = sum(weight_i * P(action_i))`

其中正反馈权重可以提高分数，负反馈权重可以压低分数。`RankingScorer` 还会做作者多样性衰减，避免同一个作者连续占据太多位置。

=== 为什么要多行为预测

如果只预测“用户会不会点赞”，系统会偏向容易点赞的内容，却可能忽略停留、回复、分享、关注作者等目标；也可能忽略“不感兴趣、屏蔽、举报”这类负反馈。

多行为预测让产品可以调权重：某个阶段更重视深度互动，另一个阶段更重视负反馈规避，或者对视频内容单独调整 video quality view 的权重。

#caution("权重不是随便调的旋钮", [
  权重改变会影响内容生态和用户体验。工程上它只是参数，产品和算法上它代表目标函数的变化。调权重前要有实验、监控和回滚方案。
])

=== 本节练习

1. 打开 #codepath("phoenix/grok.py")，用自己的话解释 `candidate_start_offset` 为什么存在。
2. 打开 #codepath("home-mixer/scorers/ranking_scorer.rs")，列出三个正反馈字段和三个负反馈字段。
3. 想一想：如果候选之间可以互相 attention，为什么同一条帖子在不同请求批次里可能分数不同？
