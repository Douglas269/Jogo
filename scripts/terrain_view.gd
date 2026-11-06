class_name TerrainView
extends Node2D
## Desenha o chão da pista em faixas verticais (evita falhas do preenchimento de formas côncavas).

const Terrain := preload("res://scripts/terrain.gd")

var from_x := -400.0
var to_x := 4000.0
var dirt_color := Color("c98d4a")
var dark_color := Color("a9702f")
var grass_color := Color("6b8f3a")


func _draw() -> void:
	var step := 4.0
	var x := from_x
	var line := PackedVector2Array()
	while x < to_x:
		var y0 := Terrain.ground_y(x)
		var y1 := Terrain.ground_y(x + step)
		var quad := PackedVector2Array([Vector2(x, y0), Vector2(x + step, y1), Vector2(x + step, 1500.0), Vector2(x, 1500.0)])
		draw_colored_polygon(quad, dirt_color)
		# faixa mais escura logo abaixo da superfície, para dar volume
		var band := PackedVector2Array([Vector2(x, y0 + 28.0), Vector2(x + step, y1 + 28.0), Vector2(x + step, 1500.0), Vector2(x, 1500.0)])
		draw_colored_polygon(band, dark_color)
		line.append(Vector2(x, y0))
		x += step
	line.append(Vector2(to_x, Terrain.ground_y(to_x)))
	draw_polyline(line, grass_color, 10.0)
