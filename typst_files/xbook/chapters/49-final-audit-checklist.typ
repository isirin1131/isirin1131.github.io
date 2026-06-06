#import "../style.typ": *

== 最终审校清单

这本书扩写到较完整版本后，需要做一次工程化审校。审校目标不是文风润色，而是确认它真的能作为学习材料使用。

=== 编译检查

必须通过：

```sh
typst compile docs/recsys-beginner-book/main.typ docs/recsys-beginner-book/book.pdf
```

如果编译失败，先修 Typst 语法，再谈内容质量。

=== 文件引用检查

用 `rg` 或 `find` 确认书中引用的路径存在：

- `candidate-pipeline/candidate_pipeline.rs`
- `home-mixer/candidate_pipeline/phoenix_candidate_pipeline.rs`
- `home-mixer/candidate_pipeline/for_you_candidate_pipeline.rs`
- `phoenix/recsys_model.py`
- `phoenix/recsys_retrieval_model.py`
- `thunder/posts/post_store.rs`
- `grox/engine.py`

如果代码文件移动，书中路径必须更新。

=== 章节覆盖检查

完整教程版应覆盖：

- 项目地图。
- 服务化推荐的分布式最小模型。
- CandidatePipeline 阶段。
- QueryHydrator、Source、Hydrator、Filter、Scorer、Selector、SideEffect。
- Phoenix Retrieval 和 Ranking。
- Thunder 和 Grox。
- 缓存、状态、可见性、安全。
- 参数、实验、数据闭环。
- 生产 runbook。
- 练习和综合项目。

缺任何一项，都会影响新手形成完整系统图。

=== 新手友好检查

每章至少应该回答：

- 这个阶段解决什么问题？
- 输入是什么？
- 输出是什么？
- 关键代码在哪里？
- 失败会怎样？
- 如何验证？

如果一章只有概念，没有代码路径和练习，应该补。

=== 技术准确性检查

重点检查：

- source/hydrator/filter/scorer 的职责是否混淆。
- cached posts 路径是否描述准确。
- candidate isolation 是否解释准确。
- side effect 是否说明不阻塞当前响应。
- safety/visibility 默认值是否没有过度承诺。
- 本地 Phoenix demo 和线上 Home Mixer 是否区分清楚。

=== 页数和结构检查

目标是约 120 页，不需要精确等于 120。更重要的是：

- 章节结构清晰。
- 每章长度适中。
- 表格和代码块不过度拥挤。
- 目录能反映学习路径。
- PDF 可读。

=== 后续出版检查

如果要把它变成更正式的书，还需要：

- 统一章节编号和文件名。
- 增加图示。
- 增加术语索引。
- 增加代码引用行号或版本号。
- 增加 changelog。
- 对中文表述做二次编辑。

=== 本节练习

1. 按本清单审查一章，记录三个改进点。
2. 随机选一个代码路径，确认书中描述仍和当前代码一致。
3. 编译 PDF 后检查目录和页码是否正常。
