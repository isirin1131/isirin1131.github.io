#import "../style.typ": *

== 综合项目，做一次端到端代码审计

最后一个实践项目：选择一次假想改动，按线上工程标准完成设计、实现、验证和回滚计划。你不需要真的改生产系统，但要用真实代码结构思考。

=== 项目题目

假设你要新增一个 source：`RecentEngagedAuthorsSource`。它从用户最近互动过的作者里取新帖子，作为 Thunder 和 Phoenix 的补充。

目标：

- 对历史互动作者做轻量召回。
- 不替代 Thunder 和 Phoenix。
- 不显著增加 P95 延迟。
- 能被参数开关控制。
- 能记录 source candidate_count 和错误率。

=== 设计文档模板

```text
背景：
目标：
非目标：
输入字段：
输出 candidate 字段：
外部依赖：
enable 条件：
最大候选数：
超时策略：
失败策略：
需要的 hydrator：
可能被哪些 filter 移除：
scoring 是否复用现有 PhoenixScorer：
selector 影响：
side effect 影响：
指标：
实验方案：
回滚方案：
```

这个模板强迫你从系统角度思考，而不是只写一个 source 文件。

=== 代码落点

可能需要修改或新增：

- `home-mixer/sources/recent_engaged_authors_source.rs`（新增文件）
- `home-mixer/sources/mod.rs`
- `home-mixer/candidate_pipeline/phoenix_candidate_pipeline.rs`
- 参数定义文件
- mock client 或测试 fixture
- README 或本书组件目录

如果 source 需要新的 query 字段，还要新增 query hydrator。不要让 source 自己偷偷访问太多上下文服务，否则边界会变乱。

=== 验证计划

至少做五类验证：

1. unit test：enable 条件。
2. unit test：外部 client 返回候选后，PostCandidate 字段正确。
3. failure test：client 失败时 source 返回 Err，pipeline 仍能使用其他 source。
4. integration-like test：加入 pipeline 后 candidate_count 增加但 filter 正常工作。
5. metrics test：source name、candidate_count、error 能被观测。

如果没有测试框架，也要写清楚人工验证步骤和日志检查方法。

=== 实验计划

实验不要只看总体互动。至少分桶：

- 新用户 vs 老用户。
- 关注数少 vs 关注数多。
- in-network only vs For You。
- 高活跃 vs 低活跃。
- source 贡献候选数量。

主要指标：

- final engagement。
- negative feedback。
- source candidate_count。
- latency P95/P99。
- duplicate rate。
- author diversity。

=== 风险清单

可能风险：

- 最近互动作者过度集中，降低多样性。
- source 返回过多旧内容。
- 和 Thunder 重叠高，增加去重成本。
- 外部依赖慢，拉高 source stage latency。
- 新用户没有历史互动，source 贡献为 0。
- 负反馈用户被错误解释为“互动作者”。

每个风险都要对应一个缓解方案，例如 max_results、年龄过滤、去重、超时、负反馈排除。

=== 复盘要求

上线后要回答：

- 这个 source 实际贡献了多少最终 selected candidates？
- 它带来的候选有多少被 filter 移除？
- 它和 Thunder/Phoenix 重叠多少？
- 它对延迟的影响是多少？
- 它对互动和负反馈的影响是多少？
- 是否对某些用户分桶明显更好或更差？

如果回答不了这些问题，说明观测性不足。

=== 本节交付物

完成项目时应产出：

- 一页设计文档。
- source 代码或伪代码。
- 测试计划。
- 指标列表。
- 实验方案。
- 回滚方案。
- 复盘模板。

这比“写出能编译的代码”更接近真实推荐系统工作。
