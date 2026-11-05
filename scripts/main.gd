extends Node2D
## Cena principal: fundo, pista, moto e os botões de gás e freio.

const Terrain := preload("res://scripts/terrain.gd")
const Bike := preload("res://scripts/bike.gd")

const TRACK_END := 3200.0

var bike: Bike
var camera: Camera2D
var gas_pressed := false
var brake_pressed := false


func _ready() -> void:
	_build_background()
	_build_track()
	bike = Bike.new()
	bike.position = Vector2(200, Terrain.ground_y(200))
	add_child(bike)
	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	camera.offset = Vector2(-220, -120)
	add_child(camera)
	_build_controls()


func _process(delta: float) -> void:
	var gas := gas_pressed or Input.is_action_pressed("ui_right")
	var brake := brake_pressed or Input.is_action_pressed("ui_left")
	bike.update_motion(delta, gas, brake)
	camera.global_position = bike.global_position


func _build_background() -> void:
	var layer := CanvasLayer.new()
	layer.layer = -10
	add_child(layer)
	var sky := TextureRect.new()
	sky.texture = load("res://assets/ceu.png")
	sky.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sky.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	sky.size = Vector2(960, 540)
	layer.add_child(sky)


func _build_track() -> void:
	# pista: preenchimento de terra e linha de grama em cima
	var pts := PackedVector2Array()
	var x := -200.0
	while x <= TRACK_END:
		pts.append(Vector2(x, Terrain.ground_y(x)))
		x += 8.0
	var fill := PackedVector2Array(pts)
	fill.append(Vector2(TRACK_END, 1200))
	fill.append(Vector2(-200, 1200))
	var dirt := Polygon2D.new()
	dirt.polygon = fill
	dirt.color = Color("c98d4a")
	add_child(dirt)
	var grass := Line2D.new()
	grass.points = pts
	grass.width = 10.0
	grass.default_color = Color("6b8f3a")
	add_child(grass)


func _build_controls() -> void:
	var ui := CanvasLayer.new()
	add_child(ui)
	var brake := _make_button(ui, "FREIO", Color("e5484d"))
	brake.button_down.connect(func(): brake_pressed = true)
	brake.button_up.connect(func(): brake_pressed = false)
	var gas := _make_button(ui, "GÁS", Color("2fbf5b"))
	gas.button_down.connect(func(): gas_pressed = true)
	gas.button_up.connect(func(): gas_pressed = false)
	# posiciona os botões no canto de baixo, já que a tela pode mudar de tamanho
	get_viewport().size_changed.connect(_layout_buttons.bind(brake, gas))
	_layout_buttons(brake, gas)


func _make_button(parent: CanvasLayer, text: String, color: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(170, 110)
	b.add_theme_font_size_override("font_size", 26)
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(20)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("pressed", sb)
	parent.add_child(b)
	return b


func _layout_buttons(brake: Button, gas: Button) -> void:
	var s := get_viewport_rect().size
	brake.position = Vector2(20, s.y - 130)
	gas.position = Vector2(s.x - 210, s.y - 150)
	gas.custom_minimum_size = Vector2(190, 130)
