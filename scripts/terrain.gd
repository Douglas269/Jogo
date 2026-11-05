class_name Terrain
extends RefCounted
## Altura do chão em cada posição horizontal da pista (y cresce para baixo).

const BASE_Y := 380.0


static func ground_y(x: float) -> float:
	return BASE_Y + sin(x * 0.0035) * 70.0 + sin(x * 0.0112 + 1.3) * 22.0
