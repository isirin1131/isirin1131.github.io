#import "../style.typ": *

== 安全和可见性，推荐系统的硬边界

推荐系统不能只追求相关性。删除、屏蔽、静音、安全策略、广告 brand safety、可见性过滤都是硬边界。本节把这些机制放在同一张图里。

=== 安全和相关性的区别

相关性回答：这个内容用户可能喜欢吗？  
安全和可见性回答：这个内容能展示吗？

两者的优先级不同。一个内容即使相关性很高，只要违反可见性规则，也必须被移除。反过来，一个内容通过安全检查，也不代表它值得推荐。

=== 可见性数据从哪里来

可见性通常由 hydrator 补字段，再由 filter 执行移除：

```text
VFCandidateHydrator
  -> candidate.visibility_reason
  -> VFFilter
  -> kept / removed
```

这种拆分让系统能记录“可见性服务返回了什么”和“filter 根据它做了什么”。

=== VFFilter 的决策

`VFFilter` 中：

```rust
Some(FilteredReason::SafetyResult(safety_result)) => {
    matches!(safety_result.action, Action::Drop(_))
}
Some(_) => true,
None => false,
```

可以理解为：

- 明确 drop：删除。
- 其他过滤理由：删除。
- 没有过滤理由：保留。

这个逻辑依赖上游正确填充 `visibility_reason`。如果 hydrator 没运行或失败，None 会被保留。因此安全链路需要额外的监控和可能的兜底策略。

=== 社交关系安全

`AuthorSocialgraphFilter` 保护用户控制：

- viewer blocked author。
- viewer muted author。
- author blocked viewer。
- quote/retweet 涉及的作者关系。

这类过滤通常在 scoring 前执行，因为没必要给用户明确不想看的内容打分。

=== 广告 brand safety

外层 feed 还要处理广告安全。广告出现在某些内容旁边可能有额外限制。相关 hydrator 包括：

- `AdsBrandSafetyHydrator`
- `AdsBrandSafetyVfHydrator`

广告安全说明推荐系统服务的不只是 viewer，还要考虑广告主、平台政策和内容上下文。

=== 内容理解和安全

Grox 这类内容理解系统会生成安全分类、摘要、embedding、标签。安全标签可能被 Home Mixer 的 hydrator 或 filter 消费。由于内容理解可能异步生成，系统要处理“标签还没到”的情况。

常见策略：

- 对高风险内容默认保守。
- 对缺标签内容降权或延迟进入某些 source。
- 对最终展示执行实时可见性检查。
- 记录缺标签率和安全服务错误率。

=== 安全链路排查

如果不该展示的内容出现，排查顺序：

1. source 是否返回了该候选？
2. core data 是否识别了正确作者、quote、retweet、reply 关系？
3. social graph filter 是否运行？
4. visibility hydrator 是否返回 reason？
5. VFFilter 是否运行？
6. post-selection 后是否又插入了未检查内容？
7. served history 和日志是否记录了该展示？

如果大量内容被误杀，排查顺序类似，但重点看 visibility_reason 分布和 filter_rate。

=== 本节练习

1. 比较 `AuthorSocialgraphFilter` 和 `VFFilter`，说明它们保护的对象不同。
2. 解释为什么安全相关过滤不应该只依赖模型分数。
3. 设计一个可见性 dashboard：至少包含 VF hydrator 错误率、VFFilter 移除率、None 比例、按 source 的移除率。

