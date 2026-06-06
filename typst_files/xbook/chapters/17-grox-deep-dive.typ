#import "../style.typ": *

== Grox 深入，内容理解怎样进入推荐

Grox 不在主 feed 排序路径里直接返回候选，但它代表推荐系统的另一条重要链路：内容理解。摘要、分类、安全标签、多模态 embedding、回复排序等结果，都会影响后续候选生成、过滤、排序或训练。

=== Engine：任务执行入口

#codepath("grox/engine.py") 的 `Engine` 从任务队列取 `TaskPayload`，然后创建异步任务执行：

```python
task = await self._poll_task()
if task is None:
    await asyncio.sleep(0.1)
    continue
asyncio.create_task(self._run_task(task))
```

这和 feed 请求的同步链路不同。Grox 更像后台任务系统：不断拉任务、执行计划、写结果。

=== PlanMaster：多个计划并行试配

#codepath("grox/plans/plan_master.py") 中有 `ALL_PLANS`：

```python
ALL_PLANS = [
    PlanInitialBanger(),
    PlanPostSafety(),
    PlanSpamComment(),
    PlanPostEmbeddingWithSummary(),
    ...
]
```

`exec` 会并行执行所有 plan：

```python
results = await asyncio.gather(*[p.execute(task) for p in cls.ALL_PLANS])
```

每个 plan 自己判断是否 eligible。不适合当前任务的 plan 返回 None，适合的 plan 产出 `TaskResult`。最后 `merge_results` 合并内容分类、embedding、reason、success/error。

=== Plan：有依赖的任务图

#codepath("grox/plans/plan.py") 的 `Plan` 支持 `TASK_DEPENDENCIES`。执行时，它为依赖任务创建 future，然后并行调度所有任务：

```python
await asyncio.gather(
    *[self._execute_task(t, ctx, dependencies) for t in self.TASKS.keys()]
)
```

每个 task 在执行前等待自己的依赖：

```python
dep_futures = [dependencies[d] for d in deps]
dep_results = await asyncio.gather(*dep_futures)
```

这比简单的顺序任务列表更灵活。没有依赖的任务可以并行，有依赖的任务等前置结果。

=== 内容理解结果如何影响推荐

Grox 的结果可能进入推荐系统的多个位置：

- 安全分类进入 visibility 或 safety filter。
- 摘要和 embedding 进入 retrieval corpus 或相似度模型。
- 话题分类进入 topic source、topic filter 或用户兴趣建模。
- 回复排序信号进入 reply ranking 或会话展示。
- 多模态描述帮助模型理解图片、视频和文本之外的内容。

这些结果不一定在用户刷新 feed 时实时计算。更多时候，它们提前生成并写入存储，推荐请求只读取这些结果。

=== 后台内容理解的优点和风险

优点：

- 把昂贵模型计算从在线请求中移走。
- 允许重试、批处理和异步补偿。
- 让多个下游系统复用同一份内容理解结果。

风险：

- 结果有延迟，新内容可能暂时缺标签或 embedding。
- 任务失败会造成数据缺口。
- 多个计划合并时要处理部分成功。
- 内容理解模型更新会影响推荐效果，需要版本和回放。

=== Grox 和 Candidate Hydration 的关系

Candidate hydrator 经常读取内容理解结果。例如安全标签、摘要、话题、embedding。Grox 更偏“生产这些结果”，Home Mixer 更偏“消费这些结果”。把生产和消费分开，可以降低在线延迟，但也引入数据新鲜度和一致性问题。

=== 本节练习

1. 在 `PlanMaster.ALL_PLANS` 中选三个 plan，推测它们处理哪类任务。
2. 打开一个具体 plan，画出它的 `TASKS` 和 `TASK_DEPENDENCIES`。
3. 解释为什么内容安全分类更适合提前计算，而不是每次 feed 请求时现算。

