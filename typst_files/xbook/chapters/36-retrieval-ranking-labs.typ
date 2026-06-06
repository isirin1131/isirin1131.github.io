#import "../style.typ": *

== 召回和排序实验课

这一节给出几个不依赖完整线上环境的思考实验。它们帮助你理解 top K、权重、多样性和负反馈如何改变结果。

=== 实验一：召回 top K

假设 corpus 有 100000 条内容，retrieval 返回 top 200。Ranking 只能处理这 200 条。即使某条内容在 ranking 模型下会排第 1，如果 retrieval 没召回它，它也不会出现。

这说明召回质量决定上限，排序质量决定最终顺序。

练习：把 top K 从 200 改成 50，会发生什么？

- Ranking 成本下降。
- 漏召回风险上升。
- 后续 hydration 和 filter 成本下降。
- 如果 filter 移除率高，最终候选可能不足。

=== 实验二：过滤对召回深度的影响

假设 retrieval top 200 中：

- 20 条重复。
- 30 条太旧。
- 15 条被屏蔽或静音。
- 25 条可见性不通过。

剩下只有 110 条。此时 selector 的 top K 再高也没用，因为候选已经被过滤掉。

所以 source 的 max_results 要考虑过滤率。高过滤率场景需要更深召回，或提升 source 质量。

=== 实验三：多行为权重

假设两个候选：

```text
A: favorite=0.20, reply=0.02, dwell=0.30, not_interested=0.01
B: favorite=0.12, reply=0.08, dwell=0.45, not_interested=0.03
```

如果 favorite 权重高，A 可能排前。  
如果 reply/dwell 权重高，B 可能排前。  
如果 not_interested 权重很负，B 可能被压下去。

这说明“好内容”不是固定概念，而是目标函数决定的。

=== 实验四：作者多样性

假设 top 5 原始分：

```text
1. author X, score 0.90
2. author X, score 0.88
3. author Y, score 0.86
4. author X, score 0.84
5. author Z, score 0.80
```

作者多样性会衰减 X 的第 2 条、第 3 条，使 Y 或 Z 有机会提前。它不是认为 X 的内容不好，而是优化 feed 序列体验。

=== 实验五：缓存路径

假设 Redis 缓存有 700 条候选，超过阈值。系统会：

- `has_cached_posts=true`
- `CachedPostsSource` 启用
- Thunder/Phoenix/CoreDataHydrator 等跳过或减少工作

如果缓存只有 100 条候选，低于阈值，系统回到实时路径。这个实验说明缓存命中也有质量门槛。

=== 实验六：side effect 失败

假设 `UpdateServedHistorySideEffect` 失败，但当前请求成功返回。用户下一次刷新可能再次看到相同内容。  
假设 `ServedCandidatesKafkaSideEffect` 失败，用户体验当下不变，但训练和实验数据缺失。

这说明后台失败有延迟影响，不一定立刻显性。

=== 本节练习

1. 构造 5 个候选，手算不同权重下的排序。
2. 构造一个 filter pipeline，计算每一层后剩余候选数。
3. 解释为什么召回 top K 和过滤率要一起调。
4. 设计一个实验，观察 author diversity 对用户体验的影响。

