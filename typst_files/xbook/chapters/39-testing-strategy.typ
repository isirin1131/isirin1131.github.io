#import "../style.typ": *

== 测试策略，推荐系统该测什么

推荐系统测试不能只测“函数返回不报错”。它要保护阶段合约、字段语义、候选数量、排序不变量和模型推理形状。本节从已有 Phoenix 测试出发，扩展到 Home Mixer 流水线应该怎样测。

=== Phoenix 测试给出的启发

#codepath("phoenix/test_recsys_model.py") 中有一组 `make_recsys_attn_mask` 测试。它们不是只测 shape，而是逐项验证语义：

- user/history 保持 causal attention。
- candidates 能看 user/history。
- candidates 能看自己。
- candidates 不能看其他 candidates。
- single candidate 和 all candidates 边界情况。

这是好测试的特征：它保护模型设计意图，而不是只保护实现细节。

=== Retrieval 测试

#codepath("phoenix/test_recsys_retrieval_model.py") 测 `CandidateTower`：

- 输出 shape 正确。
- 输出 L2 normalized。
- mean pooling 模式没有参数。
- full retrieval model 输出 user representation 和 top K。

这些测试保护 two-tower 的核心不变量：向量维度、归一化、top K 输出。

=== Pipeline 合约测试

对 `candidate-pipeline`，最重要的是合约测试：

#table(
  columns: (1.5fr, 3.2fr),
  inset: 5pt,
  stroke: 0.5pt + line,
  [合约], [测试],
  [Hydrator 长度一致], [模拟 hydrator 少返回一个结果，确认框架返回错误并不错位更新。],
  [Scorer 长度一致], [模拟 scorer 结果长度错误，确认候选 score 不被错误写入。],
  [Filter 顺序], [两个 filter 顺序运行，第二个只看到第一个 kept。],
  [Source 降级], [一个 source 返回 Err，另一个 source 成功，最终仍有候选。],
  [Side effect 后台], [side effect 不改变当前 selected candidates。],
)

这些测试比具体业务组件更基础，一旦破坏会影响所有 pipeline。

=== 组件单元测试

每类组件都有典型测试：

- QueryHydrator：mock client 返回数据，验证 query 字段被 update。
- Source：mock downstream 返回 candidates，验证 PostCandidate 字段和 enable 条件。
- Hydrator：输入候选，mock client 返回字段，验证 update 只写自己负责字段。
- Filter：构造 kept/removed 边界样本。
- Scorer：构造 PhoenixScores，验证 weighted_score 和 final score。
- Selector：构造 score 列表，验证排序和截断。
- SideEffect：mock publisher/client，验证 payload 和 enable 条件。

=== 集成式测试

推荐系统还需要小规模集成测试。可以用 mock pipeline：

```text
query hydrator -> 2 sources -> 1 hydrator -> 2 filters -> 1 scorer -> selector
```

验证：

- 候选数量每阶段符合预期。
- 被过滤候选进入 filtered_candidates。
- selected 和 non_selected 正确。
- side effect 收到正确输入。

这类测试不需要真实模型和真实 Redis，但要保护数据流。

=== 回归测试样本

对于线上 bug，建议把最小复现转成 fixture：

```text
bug: repeated retweet appears twice
fixture:
  source A returns original tweet
  source B returns retweeting tweet
expected:
  retweet dedup filter removes one
```

每个生产事故都应该沉淀一个测试或至少一个 runbook 检查项。

=== 测试不该做什么

不要把测试写成“复制实现”。例如 filter 里用了 HashSet，测试不需要关心 HashSet，只需要关心重复 tweet id 被移除。

不要在单元测试里依赖真实外部服务。source/hydrator/scorer 的外部 client 应该 mock。

不要只测 happy path。推荐系统的核心能力之一是部分失败时继续服务。

=== 本节练习

1. 给 `DropDuplicatesFilter` 写 3 个测试用例。
2. 给 `CoreDataCandidateHydrator` 写一个 cache hit 和一个 cache miss 测试。
3. 给 `PhoenixSource` 写 enable 条件测试表。
4. 把一次空结果 runbook 转成集成测试 fixture。

