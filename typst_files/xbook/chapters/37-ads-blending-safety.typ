#import "../style.typ": *

== 广告混排和安全间隔

广告混排是 feed 系统里的特殊主题。它既要满足商业投放，也要保护用户体验和内容安全。本节看 `SafeGapAdsBlender`。

=== AdsBlender 的位置

广告不是帖子 scorer 的一部分。它在外层 For You pipeline 作为 `AdsSource` 返回 `FeedItem::Ad`，然后由 `BlenderSelector` 混入最终 feed。

这样设计有几个好处：

- 帖子排序和广告插入解耦。
- 广告有独立的候选来源和安全约束。
- 混排可以根据产品规则调整，而不影响帖子 ranker。

=== SafeGapAdsBlender

#codepath("home-mixer/ads/safe_gap_blender.rs") 的核心：

```rust
let safe_gaps = find_safe_gaps(&scored_posts);
let spacing = compute_spacing(&ads);
let first_ideal = ads[0].insert_position.max(0) as usize;
let placements = assign_ads_to_gaps(&safe_gaps, ads.len(), &spacing, first_ideal);
```

它不是简单按广告要求的位置插入，而是先找 safe gaps，再根据 spacing 分配广告位置。

=== safe gap 的意义

safe gap 可以理解为“广告可以插入的位置”。某些内容附近不适合放广告，例如安全风险内容、敏感上下文、或产品上不希望打断的结构。

广告安全不只是广告本身安全，还包括广告附近的 organic 内容是否合适。

=== spacing

广告之间要有间隔。间隔太小，用户体验差；间隔太大，投放不足。`assign_ads_to_gaps` 会考虑 ideal 位置和 min 位置：

```rust
let ideal = prev_ideal + spacing.requested;
let min = (prev_ideal + spacing.min).max(last_actual + DEFAULT_SPACING.min);
```

这说明混排是约束求解问题：既要接近理想位置，又要满足最小间隔和 safe gap。

=== 如果没有足够 safe gaps

`find_best_gap` 找不到合适位置时，后续广告不会插入。这比强行插入更安全。

这类逻辑体现了商业目标和用户体验之间的边界：广告收益重要，但不能破坏安全和体验约束。

=== 广告日志

广告 item 在 served candidates side effect 中会记录 `promotedTweet`、advertiser id、insert position、impression id 等。广告日志比普通帖子更复杂，因为它还服务计费、归因和投放分析。

=== 本节练习

1. 解释为什么广告混排放在外层 For You pipeline。
2. 设计一个有 20 条帖子和 3 条广告的 safe gap 分配例子。
3. 如果 safe gaps 只有 1 个，系统应该插入几条广告？为什么？
4. 讨论广告插入如何影响 organic post 的 position。

