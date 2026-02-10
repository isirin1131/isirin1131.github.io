#import "@preview/basic-document-props:0.1.0": simple-page
#show: simple-page.with("刌刈", "isirin1131@outlook.com", middle-text: "深圳游记", date: true, numbering: true, supress-mail-link: true)

#set text(font: ("Sarasa Fixed Slab SC"), lang:("zh"))

#show math.equation: set text(font: "Neo Euler")

来深圳才俩月又要走了，本来是来这里当保安的，结果阴差阳错回归本业了，锻炼了一下业务能力。

公司的代码暂时都是单 app 架构，没啥复用价值，社交项目要改分布式，但应该是我离职之后的事情了。最后几天写了个小框架，leader 说开源也无所谓，那就放出来吧。顺便更新一下简历。

大约返校之前专科的毕设可以完成，那个时间节点我预计应该在搞 llvm 和 ysyx，或者年后投到合适的又去实习了。关于本科毕设的分布式项目，可能时间不是很好安排，毕竟还有很多想做的事情。但栈已经大概确定下来了，初期雏形大约是 go + elysia.js(with bun) + rust(推荐系统组件) 写服务，k3s(with Kine + 独立 PG 实例) 做调度，NATS(with JetStream) 做业务消息总线，HAProxy 负载均衡，PostgreSQL 做业务数据存储，LGTM 方面就直接用 AI 给的这个方案：

```
数据采集/中转：Vector (Rust)
指标存储：VictoriaMetrics (VM) — 极简、高性能。
日志存储：VictoriaLogs (VL) — 存储密度极高。
链路追踪：Grafana Tempo (可选) — 存到 S3/Local Disk，不需要 DB。
展示与告警：Grafana — 统一入口。
```

实际上预计比较重的产品功能也就推荐系统和实时协作这两项，

本来打算在这边的抽铁条俱乐部开个会员，但作为单休牛马，实在是有心无力，可叹。最重要且最有价值的东西是时间。

valve 的 steam 新硬件延期了，因为 AI 巨头导致的内存短缺。我这两个月一直在做 AI 相关下游的东西，平时编程也不少使唤 AI，有种不知该哭该笑的感觉。

不管怎么样，实习时长凑够了，两点一线的日子也该暂停了。回家享福。

注意到，来一线城市却还没到处逛逛，但深圳唯一值得去的景点可能是华强北……

嘛，事情稍多，不写了。今天小年，恰点饺子去。