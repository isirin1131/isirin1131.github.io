#let ink = rgb("#17202a")
#let muted = rgb("#5f6b7a")
#let line = rgb("#d7dde6")
#let blue = rgb("#1f6feb")
#let green = rgb("#0f766e")
#let amber = rgb("#9a6700")
#let red = rgb("#b42318")

#let note-box(kind, title, body, fill, stroke) = block(
  width: 100%,
  inset: 10pt,
  radius: 4pt,
  fill: fill,
  stroke: 0.7pt + stroke,
)[
  #text(weight: "bold", fill: stroke)[#kind：#title]
  #v(4pt)
  #body
]

#let tip(title, body) = note-box("提示", title, body, rgb("#f4f8ff"), blue)
#let beginner(title, body) = note-box("新手视角", title, body, rgb("#f3fbf7"), green)
#let caution(title, body) = note-box("小心", title, body, rgb("#fff8e8"), amber)
#let checkpoint(title, body) = note-box("检查点", title, body, rgb("#fff5f5"), red)

#let codepath(path) = text(
  font: ("Hack Nerd Font Mono", "Menlo", "Courier New"),
  size: 8.8pt,
  fill: green,
)[#path]

#let term(name, explanation) = [
  #strong[#name]：#explanation
]

