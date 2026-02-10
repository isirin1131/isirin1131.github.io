#import emoji: star
#import "@preview/bone-resume:0.3.0": resume-init, resume-section


#show: resume-init.with(
  author: "田照涛",
)

#set text(font: ("Sarasa Mono SC"), lang: ("zh"))


#stack(dir: ltr, spacing: 1fr, text(24pt)[*田照涛*], stack(
  spacing: 0.75em,
  [微信: telzert],
  [电话: 13793971886],
  [邮箱: #link("isirin1131@outlook.com")],
), stack(
  spacing: 0.75em,
  [Gitee: #link("https://gitee.com/isirin1131_admin")],
  [GitHub: #link("https://github.com/isirin1131")],
  [个人主页: #link("https://isirin1131.github.io")],
),

move(
  dy: -2em, box(height: 84pt, width: 50pt, image("IMG_20250514_182300.jpg"))
)

)

#v(-4em)
= 教育背景
贵州轻工职业技术学院（大三在读） #h(2cm) 大数据技术 #h(1fr) 2023.09-2026.07\


= 开源贡献
#resume-section(
  link("https://github.com/isirin1131/FlowCabal")[FlowCabal],
  "工作流+Agent，面向长篇小说场景。",
)[
  独立开发。相关论文见 #link("https://isirin1131.github.io/[006]%E4%BA%8C%E6%89%8B%E5%BD%B1%E8%AF%84/%E6%AF%95%E4%B8%9A%E8%AE%BE%E8%AE%A120260204.pdf")[此]。
]

#resume-section(
  link("https://github.com/isirin1131/plugram")[plugram],
  "telegram-bot 插件式快速批量开发框架，基于 aiogram",
)[
  独立开发。
]

= 实习经历

#resume-section(
  [杭州泰乐够网络有限公司],
  "2025.12.08-2026.02.14",
)[

后端开发，telegram-bot 交互开发，兼一些运维和测试的杂活，在职时共合并 43 个 PR，参与一个老项目 kissme 的维护和新功能开发，一个新项目 blink 的开发，一个投放工具性质项目 ads-bot 的两次重构升级。

+ kissme：除小改动和bot交互组件修改外，修改了 llm-client 的接口支持，添加了邀请限制和非会员限制等运营特性和一些推送特性，为 telegram-miniapp 内的流式聊天功能提供支持，为 STT 功能提供支持，整备日志模块和部署脚本。
+ blink：参与前期预研，编写 service 和 bot 交互逻辑，设计注册表单的模板化，编写第一版推荐系统（过滤器，距离筛选和意图匹配）。
+ ads-bot：维护和新功能开发；主导第一次重构，添加类 FSM 的交互模式；主导第二次重构，以 sqlite 的共享表、高抽象 service 和基于 event_bus 的高解耦化高复用化的插件式开发方式，达到批量生产高质量用完即弃 telegram-bot 的效果。

]

#resume-section(
  [福建永泰清云之尚科技有限公司],
  "2025.05.23-2025.09.01",
)[

全栈开发。

+ 单片机相关工作， 涉及 ESP32 系列的 S3 C3 等芯片，独立编写 BLE HID 鼠标键盘相关代码，以及 WIFI 视频流传输相关代码。wifi-udp 方面，手机-热点-单片机双节点低复杂度组网情况下实现低开销应用层极简协议（协议封装零拷贝）添加注册优先级机制并重构模拟变量机制。
+ 为 Autojs Pro 编写与打包 BLE 和 Netty 的相关功能，打包形式是 .dex 文件
+ 修改 PaddleOCR-V5 部署包的 JNI 层，将其移植到安卓系统，并做了 Autojs Pro 的适配，解决了一些子线程上下文与栈内存问题。
]
// #resume-section(
//   [#link("https://github.com/PaddlePaddle/PaddleSOT")[百度飞桨框架开发-动转静小组]（线上实习）],
//   "2023.07.01-2023.10.31",
// )[
// 主要工作是参与 #link("https://github.com/PaddlePaddle高性能单机、分布式训练和跨平台部署框架/PaddleSOT")[PaddleSOT] 的开发，主要贡献包括：
// + 添加注册优先级机制并重构模拟变量机制。
// + 优化字节码模拟执行报错信息和`GitHub Actions`日志信息。
// + 实现 `VariableStack` 并添加子图打断的`Python3.11`支持。
// ]
// #resume-section(
//   [#link("https://github.com/PaddlePaddle/Paddle")[百度飞桨框架开发-PIR项目]（线上实习）],
//   "2023.11.01-2024.05.31",
// )[
// 主要工作是参与 #link("https://github.com/PaddlePaddle/Paddle")[Paddle] 中 PIR
// 组件的开发，主要贡献包括：
// + Python API 适配升级。
// + API 类型检查的生成机制实现。
// + 添加 `InvalidType` 错误类型。
// ]

= 证书

信息安全管理员三级

= 个人荣誉

NOIP2020提高组一等奖

ICPC2020区域赛济南赛区铜牌

贵州省职业技能大赛2024（嵌入式系统应用开发）学生赛一等奖
