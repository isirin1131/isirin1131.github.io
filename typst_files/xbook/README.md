# 读懂 x-algorithm

这是基于当前 `x-algorithm` 项目的 Typst 教程书，目标是讲透这个项目，并在读代码过程中补充推荐算法、异步服务、分布式系统和生产工程知识。

## 编译

```sh
typst compile docs/recsys-beginner-book/main.typ docs/recsys-beginner-book/book.pdf
```

## 结构

- `main.typ`：书籍入口、全局版式和章节 include。
- `style.typ`：提示框、术语、代码路径等样式。
- `chapters/`：分章内容。

## 当前覆盖

- 11 个正文大章加 3 个附录，原 50 多个短章已降为节，避免目录碎片化。
- 主线按“项目地图 -> Candidate Pipeline -> Phoenix -> Home Mixer -> 组件深读 -> 状态/安全 -> 数据闭环 -> 生产工程 -> 实战 -> 工具箱”推进。
- `CandidatePipeline::execute` 的端到端数据流，以及 fan-out 并行阶段与顺序 filter/scorer 的区别。
- Phoenix Retrieval 的 two-tower 召回、Phoenix Ranking 的输入拼接、candidate isolation 和多行为预测。
- Home Mixer、Thunder、Grox、side effects、缓存状态、安全可见性和广告混排的服务化视角。
- 代表性 source、hydrator、filter、scorer、selector 的逐文件深度导读。
- 空结果、慢请求、重复内容、日志缺失、P99 延迟等生产排查 runbook。
- 参数、实验、训练评估、观测性 dashboard、测试策略和上线清单。
- 工作簿、复习题、调试场景题，以及附录中的参考解答。

## 120 页版审校目标

目标版本按实用教程书组织，正文约 11 个大章、约 120 页。每章围绕一个稳定问题展开：这一层在项目里解决什么问题、输入是什么、输出是什么、依赖哪些服务或模型、如何失败、如何验证。

当前版本已经完成一次结构审校：短章不再作为同级章出现，而是收进大章作为节；附录补充了工作簿、复习题和调试场景的参考解答。

当前状态：

- PDF 页数：126 页。
- 章节源文件：59 个。
- Typst/README 源码规模：约 6400 行。
- 验证命令：`typst compile docs/recsys-beginner-book/main.typ docs/recsys-beginner-book/book.pdf`。

页数预算：

- 读者导入、项目地图、学习路线：约 15 页。
- Candidate Pipeline、服务化依赖、请求生命周期、数据模型：约 24 页。
- Phoenix retrieval/ranking、本地实验和模型内部：约 24 页。
- Home Mixer 和组件主流程：约 24 页。
- 组件深读、状态、安全、数据闭环和生产工程：约 42 页。
- 实战、工具箱和附录参考解答：约 18 页。
