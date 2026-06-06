#import "../style.typ": *

== Filter 深度导读，硬约束怎样落地

Filter 是推荐系统里的硬约束执行层。这一节带读三个代表：`CoreDataHydrationFilter`、`AuthorSocialgraphFilter`、`VFFilter`。

=== CoreDataHydrationFilter：数据完整性

#codepath("home-mixer/filters/core_data_hydration_filter.rs") 只有一行核心逻辑：

```rust
let (kept, removed) = candidates.into_iter().partition(|c| c.author_id != 0);
```

它把 `author_id != 0` 当成候选作者信息是否有效的代理信号。为什么不是检查 tweet_text？因为 author id 是更基础的关系字段，后续社交图过滤、作者多样性、日志都依赖它。

这个 filter 展示了一个常见模式：hydrator 负责补字段，filter 负责检查字段是否足够完整。

=== AuthorSocialgraphFilter：用户控制

#codepath("home-mixer/filters/author_socialgraph_filter.rs") 先把 blocked/muted list 转成 HashSet：

```rust
let viewer_blocked_user_ids: HashSet<i64> =
    query.user_features.blocked_user_ids.iter().copied().collect();
```

然后对每个 candidate 检查多个关系：

- author 是否被 viewer muted。
- author 是否被 viewer blocked。
- author 是否 block viewer。
- quoted author 是否 block viewer。
- viewer 是否 block quoted author。
- viewer 是否 block retweeted user。

这说明社交图过滤不只看候选作者。quote、retweet、reply 都可能把其他用户带进展示上下文。

=== VFFilter：可见性最终检查

#codepath("home-mixer/filters/vf_filter.rs") 使用 `visibility_reason`：

```rust
fn should_drop(reason: &Option<FilteredReason>) -> bool {
    match reason {
        Some(FilteredReason::SafetyResult(safety_result)) => {
            matches!(safety_result.action, Action::Drop(_))
        }
        Some(_) => true,
        None => false,
    }
}
```

这个逻辑很值得细看：

- `SafetyResult` 且 action 是 Drop，则移除。
- 其他 Some(reason) 也移除。
- None 不移除。

这意味着 `visibility_reason` 的存在通常代表已经有过滤理由；没有理由则默认保留。这个默认是否安全，取决于上游 VFCandidateHydrator 是否可靠，以及是否还有其他可见性保护。

#caution("安全相关默认值要特别审查", [
  对推荐相关字段，缺失可能只是效果下降；对安全和可见性字段，缺失可能造成错误展示。读这类代码时要明确 None 的语义。
])

=== Filter 顺序案例

一个合理顺序可能是：

```text
DropDuplicatesFilter
CoreDataHydrationFilter
AgeFilter
SelfTweetFilter
AuthorSocialgraphFilter
...
VFFilter (post-selection)
```

前面的 filter 通常便宜、确定、能减少候选。后面的 filter 可能依赖昂贵 hydration 或只需要对选中的候选做最终检查。

=== 过滤率解读

过滤率高不一定坏。比如 DropDuplicatesFilter 高，可能说明多 source 重叠高；VFFilter 高，可能说明上游候选质量差或可见性策略变严。关键是结合 source 和阶段看。

排查时不要只问“为什么删了这么多”，要问：

- 哪个 source 的候选被删得最多？
- 删除发生在 scoring 前还是 post-selection？
- filter 输入量是否异常？
- 删除是否和参数或模型发布同一时间变化？

=== 本节练习

1. 分析 `CoreDataHydrationFilter` 为什么用 `author_id != 0`。
2. 给 `AuthorSocialgraphFilter` 画一张关系检查图。
3. 解释 `VFFilter` 中 `Some(_) => true` 的含义和风险。
4. 设计一个 filter 指标面板，能区分 source 质量和 filter 策略变化。
