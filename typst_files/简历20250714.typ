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
  [邮箱: #link("13793971886@139.com")[13793971886\@139.com]],
), stack(
  spacing: 0.75em,
  [Gitee: #link("https://gitee.com/isirin1131_admin")[gitee.com/isirin1131_admin]],
  [个人主页: #link("https://isirin1131.github.io/")[isirin1131.github.io]],
),

move(
  dy: -2em, box(height: 84pt, width: 50pt, image("IMG_20250514_182300.jpg"))
)

)

#v(-4em)
= 教育背景
贵州轻工职业技术学院（大二在读） #h(2cm) 大数据技术 #h(1fr) 2023.09-2026.07\


// = 开源贡献
// #resume-section(
//   link("https://github.com/PaddlePaddle/CINN")[PaddlePaddle/CINN],
//   "针对神经网络的编译器基础设施",
// )[
//   添加了 argmax, sort, gather, gather_nd, scatter_nd 等算子, 实现了 CSE Pass 和
//   ReverseComputeInline 原语以及参与了一些单元测试补全，具体内容见
//   #link(
//     "https://github.com/PaddlePaddle/CINN/pulls?q=is%3Apr+author%3Azrr1999+is%3Aclosed",
//   )[相关 PR]。
// ]

// #resume-section(
//   link("https://github.com/PaddlePaddle/Paddle")[PaddlePaddle/Paddle],
//   "高性能单机、分布式训练和跨平台部署框架",
// )[
//   添加了 remainder\_, sparse_transpose, sparse_sum 三个算子， 实现了 TensorRT onehot
//   算子转换功能，以及修复了一些bug，具体内容见
//   #link(
//     "https://github.com/PaddlePaddle/Paddle/pulls?q=is%3Apr+author%3Azrr1999+is%3Aclosed",
//   )[相关 PR]。
// ]

= 实习经历

暂无

#resume-section(
  [福建永泰清云之尚科技有限公司],
  "2025.05.23-2026.1.30",
)[

+ 单片机相关工作， 涉及 ESP32 系列的 S3 C3 等芯片，独立编写 BLE HID 鼠标键盘相关代码，以及 WIFI 视频流传输相关代码。wifi-udp 方面，手机-热点-单片机双节点低复杂度组网情况下实现低开销应用层极简协议（协议封装零拷贝）添加注册优先级机制并重构模拟变量机制。
+ 为 Autojs Pro 编写与打包 BLE 和 Netty 的相关功能，打包形式是 .dex 文件
+ 修改 PaddleOCR-V5 部署包的 JNI 层，将其移植到安卓系统，并做了 Autojs Pro 的适配，解决了一些子线程上下文与栈内存问题。
]
// #resume-section(
//   [#link("https://github.com/PaddlePaddle/PaddleSOT")[百度飞桨框架开发-动转静小组]（线上实习）],
//   "2023.07.01-2023.10.31",
// )[
// 主要工作是参与 #link("https://github.com/PaddlePaddle/PaddleSOT")[PaddleSOT] 的开发，主要贡献包括：
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


= 个人技能

熟练阅读英文文档，数学能力较强

#let stars(num) = {
  for _ in range(num) {
    [#emoji.star]
  }
}

#let level(num, desc: none) = {
  if desc == none {
    if num < 3 {
      desc = "了解"
    } else if num < 5 {
      desc = "掌握"
    } else if num < 7 {
      desc = "熟练"
    } else {
      desc = "精通"
    }
  }
  // [(#desc) #stars(num)]
  [#desc]
}

#grid(
  columns: (60pt, 1fr, auto),
  rows: auto,
  gutter: 6pt,
  "基本",
  [熟练使用命令行、vim、git、docker、systemd(nginx、MYSQL、hadoop全家桶) 等基本工具 ],
  level(7),
  "Python",
  [有 opencv/open3d 项目经验，熟悉 conda、uv 等虚拟环境管理工具],
  level(6),
  "C/C++",
  [熟悉 xmake、Makefile 等构建工具，写过数万行代码],
  level(6),
  "Java",
  [熟练使用 Maven 等构建工具，有中小型 Spring Web 项目经验],
  level(6),
  
)

