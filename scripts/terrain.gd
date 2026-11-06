class_name Terrain
extends RefCounted
## Altura do chão em cada posição horizontal da pista (y cresce para baixo).
## As rampas da fase ficam em `ramps`. Tipos:
##   "jump": sobe reto até a ponta e cai de repente (rampa de salto)
##   "hill": morro suave (serve de pouso)

const BASE_Y := 380.0
const CLIFF := 12.0   # largura da queda logo depois da ponta da rampa

static var ramps: Array = []


static func set_ramps(list: Array) -> void:
	ramps = list


static func ground_y(x: float) -> float:
	var y := BASE_Y + sin(x * 0.0035) * 20.0 + sin(x * 0.0112 + 1.3) * 6.0
	for r in ramps:
		var x0: float = r.x
		var ln: float = r.len
		var h: float = r.h
		if str(r.type) == "hill":
			if x > x0 and x < x0 + ln:
				var t := (x - x0) / ln
				y -= h * 0.5 * (1.0 - cos(TAU * t))
		else:
			if x >= x0 and x <= x0 + ln:
				y -= h * (x - x0) / ln
			elif x > x0 + ln and x < x0 + ln + CLIFF:
				y -= h * (1.0 - (x - x0 - ln) / CLIFF)
	return y
