#import "../style.typ": *

== 推荐系统设计模式

本项目中有一些可复用设计模式。理解它们，可以帮助你阅读其他推荐系统。

=== 分阶段流水线

把请求拆成固定阶段：hydrate query、source、hydrate candidate、filter、score、select、side effect。

收益：

- 组件边界清晰。
- 易于并行化。
- 易于观测。
- 易于复用。

代价：

- 字段在多个阶段逐步变化，需要清晰数据模型。
- 组件太多时需要目录和规范。

=== 只写自己负责的字段

hydrator 和 scorer 返回默认 candidate，只填自己负责的字段，再由 update 合并。

收益：

- 避免组件互相覆盖。
- 便于局部失败。
- 便于测试。

风险：

- 默认值语义必须清楚。
- update 漏字段会导致下游缺数据。

=== 并行 fan-out + 顺序决策

query hydrator、source、hydrator 常并行；filter、scorer 常顺序。

原则：

- 只读同一输入的独立组件可以并行。
- 会改变候选集合或依赖前一步输出的组件顺序执行。

=== 缓存作为可降级路径

cached posts 不是旁路返回，而是重新接入 source 阶段。这样后续 filter/selector/side effect 仍能复用。

收益：

- 降延迟。
- 降下游压力。
- 保持 pipeline 结构统一。

=== 硬约束后置保护

即使缓存命中或模型分高，也要经过可见性和安全过滤。这是推荐系统的硬边界。

=== 后台 side effect

日志、缓存、served history 放后台执行，保护当前响应延迟。

风险是未来闭环受损，所以必须有观测性。

=== 参数化策略

用 feature switches 和 decider 控制数量、权重、cluster、开关，让策略可以实验和回滚。

风险是路径变多，所以需要参数记录和 dashboard。

=== 本节练习

1. 在项目中找出每个设计模式的一个例子。
2. 选择一个模式，说明它的收益和风险。
3. 想一想：如果没有分阶段流水线，Home Mixer 会变成什么样？

