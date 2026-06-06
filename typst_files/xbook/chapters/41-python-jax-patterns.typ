#import "../style.typ": *

== 给新手的 Python/JAX 读法

Phoenix 模型用 Python、JAX 和 Haiku 写。新手不必先成为 JAX 专家，但需要看懂几个模式：函数式模型、参数树、张量 shape、jit 风格和 numpy/JAX 互转。

=== JAX 数组和 numpy 数组

代码里同时出现 `np` 和 `jnp`：

- `numpy` 常用于文件加载、预处理、CPU 侧数组操作。
- `jax.numpy` 用于模型前向和可加速计算。

`run_pipeline.py` 中常见转换：

```python
jnp.asarray(user_hashes)
np.asarray(user_repr[0])
```

读法：进入模型前转成 JAX 数组；拿出来做普通 numpy 操作时转回 numpy。

=== Haiku transform

Haiku 模型通常写成函数：

```python
def rank_forward(b, e):
    return rank_model_config.make()(b, e)

rank_fn = hk.without_apply_rng(hk.transform(rank_forward))
```

`transform` 把函数变成可初始化、可应用的模型。`apply(params, ...)` 使用已有参数做前向推理。

本地 demo 加载导出的 params，所以主要用 `apply`。

=== 参数树

`load_model_params` 把 `.npz` key 拆成：

```text
module_path / param_name
```

再转成 Haiku params dict。模型代码里 `hk.get_parameter("name", shape, ...)` 会从参数树取对应权重。

如果参数名不匹配，模型无法加载或前向失败。这就是 config、代码和 checkpoint 必须一致的原因。

=== Shape 是第一层语义

JAX 模型读法从 shape 开始。Phoenix 常见 shape：

```text
B: batch size
S: history sequence length
C: candidate count
D: embedding dimension
A: action count

user_hashes: [B, num_user_hashes]
history_post_hashes: [B, S, num_item_hashes]
candidate_post_hashes: [B, C, num_item_hashes]
embeddings: [B, 1 + S + C, D]
logits: [B, C, A]
```

看懂 shape，模型主线就清楚一半。

=== Mask 测试为什么重要

`test_recsys_model.py` 里对 attention mask 写了很多测试。因为 mask 的 shape 正确不代表语义正确。候选之间如果误相互 attention，模型仍可能跑通，但排序稳定性被破坏。

机器学习系统里，最危险的 bug 往往不是崩溃，而是悄悄改变训练或推理语义。

=== 向量归一化

Retrieval 测试检查 CandidateTower 输出 L2 norm 接近 1。这是因为 retrieval 用点积做相似度。归一化后，点积更接近 cosine similarity，避免向量长度主导结果。

如果忘记归一化，top K 可能偏向向量范数大的候选，而不是方向相似的候选。

=== 本节练习

1. 在 `recsys_model.py` 中标注 B/S/C/D/A 对应位置。
2. 解释 `hk.transform` 和 `apply(params, ...)` 的关系。
3. 运行或阅读 mask 测试，说明每个测试保护哪个推荐语义。
4. 解释 retrieval 为什么要测试 L2 normalized。

