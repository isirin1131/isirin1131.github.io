#import "../style.typ": *

== Filtering，哪些候选不能继续

推荐系统不只是挑喜欢的内容，也要排除不该展示的内容。Filter 阶段负责把候选分成两类：继续参与后续流程的 kept，以及被移除的 removed。

=== Filter 的合约

#codepath("candidate-pipeline/filter.rs") 的核心类型是：

```rust
pub struct FilterResult<C> {
    pub kept: Vec<C>,
    pub removed: Vec<C>,
}

pub trait Filter<Q, C>: Any + Send + Sync {
    fn filter(&self, query: &Q, candidates: Vec<C>) -> FilterResult<C>;
}
```

filter 和 hydrator 最大的区别是：filter 可以改变候选集合大小。它拿走一批 candidates，返回 kept 和 removed。

pipeline 会顺序运行所有启用的 filter。每个 filter 只看上一个 filter 留下来的 candidates。

=== 例子一：DropDuplicatesFilter

#codepath("home-mixer/filters/drop_duplicates_filter.rs") 是最容易理解的 filter：

```rust
let mut seen_ids = HashSet::new();

for candidate in candidates {
    if seen_ids.insert(candidate.tweet_id) {
        kept.push(candidate);
    } else {
        removed.push(candidate);
    }
}
```

它解决的是多 source 召回重叠。Thunder、Phoenix、缓存都可能返回同一条帖子。如果不去重，同一内容可能在后续阶段重复补字段、重复打分，甚至重复展示。

=== 例子二：AuthorSocialgraphFilter

#codepath("home-mixer/filters/author_socialgraph_filter.rs") 处理社交关系约束。它会检查：

- viewer 是否屏蔽 author。
- viewer 是否静音 author。
- author 是否屏蔽 viewer。
- quote 或 retweet 涉及的作者是否有屏蔽关系。

这类 filter 不是“相关性”问题，而是用户控制和安全体验问题。模型认为相关，也不能越过用户明确的屏蔽和静音关系。

#caution("模型分高不等于可以展示", [
  推荐系统里有硬约束和软目标。用户屏蔽、可见性、安全、删除状态通常是硬约束；相关性、多样性、商业目标是软目标或可调目标。
])

=== 顺序为什么重要

filter 顺序会影响性能、归因和最终结果。通常有几个原则：

- 便宜的、确定性的过滤尽量靠前，例如去重。
- 依赖 hydration 字段的过滤必须放在相关 hydrator 之后。
- 安全和可见性过滤不能被省略，只能选择在合适阶段执行。
- 高移除率的 filter 靠前可以减少后续成本。

例如 `DropDuplicatesFilter` 很便宜，靠前能减少重复候选。`CoreDataHydrationFilter` 必须等 CoreDataHydrator 补完字段。`VFFilter` 在 post-selection 阶段运行，针对即将展示的候选做最终检查。

=== removed 不是垃圾数据

pipeline 保存了 filtered candidates。side effect 也能拿到 selected 和 non_selected。被移除的候选很有诊断价值：

- 哪个 filter 移除最多？
- 某次请求为什么空结果？
- 某个 source 返回的候选是否大部分不可展示？
- 某次参数调整是否导致过滤率异常上升？

因此 `Filter::run` 会记录 kept_count、removed_count、filter_rate。排查问题时，只看最终空不空是不够的，要看候选在哪一段消失。

=== Filter 里的默认值风险

filter 经常根据 `Option` 字段判断。如果默认值语义不清，就会出问题。例如：

```rust
let author_blocks_viewer = candidate.author_blocks_viewer.unwrap_or(false);
```

这表示“字段缺失时按没有屏蔽处理”。这个选择可能是为了避免过度过滤，也可能有安全风险。是否合理要结合上游 hydrator 的可靠性和后续可见性过滤一起判断。

新手读 filter 时，遇到 `unwrap_or(false)`、空列表、默认 candidate，要停下来问：缺失数据被当成允许、拒绝，还是未知？

=== 本节练习

1. 在 `phoenix_candidate_pipeline.rs` 中把 filters 列成表，标注每个 filter 依赖哪些字段。
2. 找出一个只能在 hydration 后运行的 filter，说明原因。
3. 假设某次请求最终空结果，写出你会查看的三个过滤指标。

