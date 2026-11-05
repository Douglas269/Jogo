class_name Terrain
extends RefCounted
## Altura do chão em cada posição horizontal da pista (y cresce para baixo).
## A pista tem morros suaves e rampas de salto: sobe reto até a ponta e cai de repente.

const BASE_Y := 380.0
const CLIFF := 12.0   # largura da queda logo depois da ponta da rampa

# x da base da rampa, comprimento da subida, altura
const RAMPS := [
	{"x": 1000.0, "len": 170.0, "h": 130.0},
	{"x": 2100.0, "len": 200.0, "h": 170.0},
	{"x": 3300.0, "len": 220.0, "h": 200.0},
]


static func ground_y(x: float) -> float:
	var y := BASE_Y + sin(x * 0.0035) * 40.0 + sin(x * 0.0112 + 1.3) * 12.0
	for r in RAMPS:
		var x0: float = r.x
		var ln: float = r.len
		var h: float = r.h
		if x >= x0 and x <= x0 + ln:
			y -= h * (x - x0) / ln
		elif x > x0 + ln and x < x0 + ln + CLIFF:
			y -= h * (1.0 - (x - x0 - ln) / CLIFF)
	return y
