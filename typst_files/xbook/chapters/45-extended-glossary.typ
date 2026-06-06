#import "../style.typ": *

== 扩展术语表

本节把前面反复出现的术语集中整理。它适合在读源码时作为速查表。

#term("Candidate Pipeline", [把推荐请求拆成 query hydration、source、hydration、filter、scorer、selector、side effect 的通用框架。])

#term("Query", [本次请求的上下文，包括用户、设备、场景、参数、历史行为、缓存状态等。])

#term("Candidate", [候选内容。它可能来自不同 source，只有经过过滤和选择后才会展示。])

#term("Hydration", [补字段的过程。Query hydration 补请求上下文，candidate hydration 补候选信息。])

#term("Source", [候选来源，例如 Thunder、Phoenix Retrieval、缓存、广告系统。])

#term("Filter", [硬约束或规则移除阶段，把候选分成 kept 和 removed。])

#term("Scorer", [写入排序信号的组件，可以是模型调用，也可以是加权组合或多样性调整。])

#term("Selector", [根据分数或混排规则选择最终候选。])

#term("Side effect", [响应后或响应边界附近写日志、缓存、状态、实验数据的操作。])

#term("In-network", [来自用户关注网络的内容，典型 source 是 Thunder。])

#term("Out-of-network", [关注网络之外发现的内容，典型 source 是 Phoenix Retrieval。])

#term("Retrieval", [从大规模内容中快速找一批可能相关候选的阶段。])

#term("Ranking", [对较小候选集做精细预测和排序的阶段。])

#term("Two-tower", [分别编码用户和候选到同一向量空间，用点积或相似度做召回的模型结构。])

#term("Candidate isolation", [排序 transformer 中候选不能互相 attention，保证候选分数更稳定。])

#term("Product surface", [行为或请求发生的产品场景。])

#term("Served type", [候选来源或展示类型的标记，用于响应、日志和分析。])

#term("Feature switch", [按用户、地区、客户端等动态求值的参数系统。])

#term("Decider", [用于实验或开关控制的运行时决策系统。])

#term("Fallback", [主路径失败时使用替代路径或默认值继续服务。])

#term("Degradation", [部分能力不可用时降低质量但保持服务可用。])

#term("Tail latency", [P95/P99 等尾部延迟，常决定用户体感。])

#term("Cache hit", [缓存中找到可用数据。])

#term("Cache miss", [缓存没有找到数据，需要访问下游或实时计算。])

#term("TTL", [缓存存活时间。过长影响新鲜度，过短降低命中率。])

#term("Visibility filtering", [基于安全、删除、策略、屏蔽等规则判断内容是否可展示。])

#term("Brand safety", [广告展示上下文是否符合品牌安全要求。])

#term("Served history", [记录用户近期看到的 feed item，用于去重和上下文。])

#term("Impression", [一次内容展示事实，是训练和分析的重要输入。])

#term("Negative feedback", [用户不感兴趣、屏蔽、静音、举报等负向信号。])

#term("Calibration", [模型预测概率与真实发生频率的一致程度。])

#term("A/B experiment", [把用户分到不同策略，比较线上指标。])

#term("Runbook", [生产问题的标准排查步骤。])

=== 使用方法

遇到不懂的术语时，不要只背定义。回到代码里找：

- 它是哪一阶段的概念？
- 对应哪个字段或组件？
- 是否影响当前响应？
- 是否影响后续闭环？

