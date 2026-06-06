#import "../style.typ": *

== Thunder ingestion，实时数据怎样进入内存索引

Thunder 不只是查询服务，还需要持续接收帖子创建和删除事件。虽然本节不完整展开 Kafka listener 的每个细节，但要建立实时 ingestion 的基本图景。

=== 实时索引的目标

Thunder 的目标是低延迟返回关注作者近期内容。为此，它需要：

- 快速接收新帖子事件。
- 快速处理删除事件。
- 维护按作者分组的时间队列。
- 控制内存增长。
- 在请求时快速按关注列表扫描。

这和离线 corpus 不同。离线 corpus 更关注批量计算和向量索引；Thunder 更关注新鲜度和内存结构。

=== 写入路径

Kafka listener 消费事件后，会把 `LightPost` 写入 `PostStore::insert_posts`。PostStore 会：

1. 过滤过旧和未来时间。
2. 按 created_at 排序。
3. 跳过已删除帖子。
4. 写入 `posts`。
5. 写入 per-user 队列。

这个路径把事件流转成可查询索引。

=== 删除路径

删除事件调用 `mark_as_deleted`：

```rust
self.posts.remove(&post.post_id);
self.deleted_posts.insert(post.post_id, true);
```

deleted_posts 的存在是为了处理事件乱序。如果先收到 delete，再收到 create，insert 时会检查 deleted_posts 并跳过。

实时系统必须假设事件可能乱序、重复或延迟。

=== 自动清理

`start_auto_trim` 后台定期执行：

```rust
interval.tick().await;
let trimmed = self.trim_old_posts().await;
```

清理旧帖子可以控制内存，并保证 Thunder 返回的内容足够新。

=== 请求时扫描

ThunderService 接收 following list 后，会从 PostStore 按作者取候选。为了防止过载，它使用 semaphore 限制并发。为了观察质量，它记录新鲜度、作者数、reply ratio、返回比例等指标。

这说明实时召回不是简单 HashMap 查询。它还要处理容量保护和质量监控。

=== Ingestion 和 Query Hydration 的关系

Home Mixer 通过 `FollowedUserIdsQueryHydrator` 补关注列表，然后 ThunderSource 把列表发给 Thunder。Thunder 只负责“这些作者最近有什么内容”。

边界清晰：

- Home Mixer 知道 viewer 上下文。
- Thunder 知道实时帖子索引。

=== 本节练习

1. 解释为什么 Thunder 要同时有 `posts` 和 `original_posts_by_user`。
2. 解释 deleted_posts 如何处理事件乱序。
3. 设计一个指标判断 Thunder 数据新鲜度是否下降。
4. 思考：如果 Kafka ingestion 延迟 10 分钟，For You feed 会出现什么变化？

