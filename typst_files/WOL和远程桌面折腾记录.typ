#import "@preview/basic-document-props:0.1.0": simple-page
#show: simple-page.with("刌刈", "isirin1131@outlook.com", middle-text: "telescope", date: true, numbering: true, supress-mail-link: true)

#set text(font: ("Sarasa Fixed Slab SC"), lang:("zh"))

#show math.equation: set text(font: "Neo Euler")

目标：游戏本放在家里可以远程开机+远程桌面+ssh

远程开机准备用 WOL 的方案，我有台吃灰的香橙派配置还不低，RK3588 的 16+512，本来想用 Wifi 连家里的路由器，结果 rtw89_8852be 这张无线网卡最终排查下来可能是硬件不支持还是咋地，最后只能买根 20m 网线连路由器。（为无线网卡这事我还编译了一晚上带这张卡驱动的 openwrt 第三方的内核，结果是无效折腾）

