#set page(
  width: 100pt,
  height: 100pt,
  margin: 0pt,
  fill: none,
)

#let logo-color = rgb(144, 72, 144)

#place(
  dx: 0pt,
  dy: 0pt,
  rect(
    width: 100pt,
    height: 100pt,
    fill: logo-color,
    radius: 15pt,
    inset: 0pt,
  )[
    #align(center + horizon)[
      #text(fill: white, size: 90pt, weight: "bold")[
        $t c$
      ]
    ]
  ]
)
