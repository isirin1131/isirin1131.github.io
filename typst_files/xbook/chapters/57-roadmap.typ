#import "../style.typ": *

== 后续路线

这本书已经覆盖了从新手到能读懂主链路的内容。后续如果继续完善，可以朝三个方向扩展。

=== 方向一：更多真实组件逐文件导读

可以继续增加：

- `AgeFilter`
- `MutedKeywordFilter`
- `PreviouslyServedPostsFilter`
- `QuoteHydrator`
- `LanguageCodeHydrator`
- `PhoenixTopicsSource`
- `PhoenixMOESource`
- `VMRanker`

每个文件按同一模板讲：输入、输出、外部依赖、enable、失败策略、指标、测试。

=== 方向二：图示化

当前版本以文字和表格为主。后续可以补：

- 全链路流程图。
- Query 字段生命周期图。
- Candidate 字段生命周期图。
- Candidate isolation mask 可视化。
- 缓存读写图。
- 数据闭环图。
- Dashboard 示例图。

图示能降低新手理解成本。

=== 方向三：本地可运行实验

可以新增脚本或 notebook：

- 运行 Phoenix demo。
- 构造 toy candidate pipeline。
- 可视化 attention mask。
- 手算 ranking weights。
- 模拟 source failure 和 filter rate。

把练习变成可运行代码，会让学习体验更完整。

=== 方向四：评估和训练深挖

当前书只做了训练评估入门。后续可以深入：

- 样本构造。
- 曝光偏差。
- 多任务损失。
- calibration。
- counterfactual evaluation。
- A/B 实验分析。

这部分适合读者已经掌握服务主链路之后学习。

=== 方向五：维护自动化

可以写一个简单检查脚本：

- 检查书中引用路径是否存在。
- 编译 Typst。
- 统计页数。
- 输出章节行数。
- 检查 TODO。

这样每次代码变化后都能快速确认教程没有明显过期。

=== 结束语

推荐系统入门的关键不是一次性记住所有组件，而是形成稳定读法：

```text
输入是什么？
输出是什么？
等了谁？
失败怎么办？
谁会读取这个结果？
怎样验证它？
```

只要你坚持这六个问题，再大的推荐系统也能被拆开理解。

