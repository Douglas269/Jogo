extends Node2D
## Cena principal: fundo, pista da fase, moto, controles, checkpoints e tela de fase concluída.

const Terrain := preload("res://scripts/terrain.gd")
const Bike := preload("res://scripts/bike.gd")
const Levels := preload("res://scripts/levels.gd")
const TerrainView := preload("res://scripts/terrain_view.gd")

var bike: Bike
var camera: Camera2D
var gas_pressed := false
var brake_pressed := false
var tilt_up_pressed := false
var tilt_down_pressed := false
var info_label: Label
var overlay: PanelContainer
var overlay_label: Label
var overlay_button: Button
var level_index := 0
var level: Dictionary = {}
var elapsed := 0.0
var finished := false
var _track_nodes: Array = []


func _ready() -> void:
	_build_background()
	bike = Bike.new()
	add_child(bike)
	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	camera.zoom = Vector2(0.5, 0.5)
	camera.offset = Vector2(380, -20)   # moto à esquerda e mais embaixo, para ver a rampa que vem pela frente
	add_child(camera)
	_build_controls()
	_build_overlay()
	load_level(0)


## Carrega uma fase: monta a pista, coloca a moto no começo e zera o relógio.
func load_level(i: int) -> void:
	level_index = clampi(i, 0, Levels.count() - 1)
	level = Levels.DATA[level_index]
	Terrain.set_ramps(level.ramps)
	for n in _track_nodes:
		n.queue_free()
	_track_nodes.clear()
	_build_track()
	bike.reset(Bike.START_X)
	elapsed = 0.0
	finished = false
	overlay.visible = false


func _process(delta: float) -> void:
	if not finished:
		elapsed += delta
	var gas := (gas_pressed or Input.is_action_pressed("ui_right")) and not finished
	var brake := brake_pressed or Input.is_action_pressed("ui_left")
	var tilt := 0.0
	if tilt_up_pressed or Input.is_action_pressed("ui_up"):
		tilt -= 1.0
	if tilt_down_pressed or Input.is_action_pressed("ui_down"):
		tilt += 1.0
	bike.update_motion(delta, gas, brake, tilt)
	camera.global_position = bike.global_position
	_update_checkpoint()
	_check_finish()
	_update_hud()


## Cada rampa de salto guarda um ponto seguro antes dela: se você bater, volta para lá.
func _update_checkpoint() -> void:
	for r in level.ramps:
		if str(r.type) == "jump" and bike.state == Bike.State.GROUND and bike.distance > float(r.x) - 150.0:
			bike.checkpoint_x = maxf(bike.checkpoint_x, float(r.x) - 450.0)


func _check_finish() -> void:
	if finished or bike.state != Bike.State.GROUND:
		return
	if bike.distance + Bike.WHEEL_BASE >= float(level.length):
		finished = true
		var stars := Levels.stars(bike.crashes, bike.score, int(level.target))
		var last := level_index >= Levels.count() - 1
		overlay_label.text = "Fase concluída!\n%s\n\n%s\nTempo: %.1f s    Pontos: %d    Batidas: %d" % [str(level.name), "Estrelas: %d de 3" % stars, elapsed, bike.score, bike.crashes]
		overlay_button.text = "Jogar a primeira fase de novo" if last else "Próxima fase"
		overlay.visible = true


func _update_hud() -> void:
	var status := ""
	if bike.state == Bike.State.CRASHED:
		status = "Bateu! Voltando ao último ponto..."
	elif bike.state == Bike.State.AIR and absf(bike.air_rot) > TAU * 0.8:
		status = "Giro!"
	var pct := int(clampf((bike.distance + Bike.WHEEL_BASE) / float(level.length), 0.0, 1.0) * 100.0)
	info_label.text = "Fase %d: %s   %d%%\nPontos: %d   Giros: %d   Batidas: %d   %s" % [level_index + 1, str(level.name), pct, bike.score, bike.flips, bike.crashes, status]


func _on_overlay_button() -> void:
	var next := level_index + 1
	if next >= Levels.count():
		next = 0
	load_level(next)


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
	var view := TerrainView.new()
	view.from_x = -400.0
	view.to_x = float(level.length) + 800.0
	add_child(view)
	_track_nodes.append(view)
	# linha de chegada: poste e bandeira quadriculada
	var fx := float(level.length)
	var pole := Line2D.new()
	pole.points = PackedVector2Array([Vector2(fx, Terrain.ground_y(fx)), Vector2(fx, Terrain.ground_y(fx) - 260.0)])
	pole.width = 8.0
	pole.default_color = Color("f5f5f5")
	add_child(pole)
	_track_nodes.append(pole)
	var flag := Polygon2D.new()
	var fy := Terrain.ground_y(fx) - 260.0
	flag.polygon = PackedVector2Array([Vector2(fx, fy), Vector2(fx + 110, fy + 30), Vector2(fx, fy + 70)])
	flag.color = Color("e5484d")
	add_child(flag)
	_track_nodes.append(flag)


func _build_controls() -> void:
	var ui := CanvasLayer.new()
	add_child(ui)
	var brake := _make_button(ui, "FREIO", Color("e5484d"))
	brake.button_down.connect(func(): brake_pressed = true)
	brake.button_up.connect(func(): brake_pressed = false)
	var gas := _make_button(ui, "GÁS", Color("2fbf5b"))
	gas.button_down.connect(func(): gas_pressed = true)
	gas.button_up.connect(func(): gas_pressed = false)
	var up := _make_button(ui, "EMPINAR", Color("3b82c4"))
	up.button_down.connect(func(): tilt_up_pressed = true)
	up.button_up.connect(func(): tilt_up_pressed = false)
	var down := _make_button(ui, "INCLINAR", Color("3b82c4"))
	down.button_down.connect(func(): tilt_down_pressed = true)
	down.button_up.connect(func(): tilt_down_pressed = false)
	info_label = Label.new()
	info_label.position = Vector2(16, 12)
	info_label.add_theme_font_size_override("font_size", 20)
	info_label.add_theme_color_override("font_color", Color.WHITE)
	info_label.add_theme_color_override("font_outline_color", Color.BLACK)
	info_label.add_theme_constant_override("outline_size", 6)
	ui.add_child(info_label)
	# posiciona os botões no canto de baixo, já que a tela pode mudar de tamanho
	var all := [brake, gas, up, down]
	get_viewport().size_changed.connect(_layout_buttons.bind(all))
	_layout_buttons(all)


func _build_overlay() -> void:
	var ui := CanvasLayer.new()
	ui.layer = 10
	add_child(ui)
	overlay = PanelContainer.new()
	overlay.visible = false
	overlay.position = Vector2(230, 120)
	overlay.custom_minimum_size = Vector2(500, 280)
	ui.add_child(overlay)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	overlay.add_child(box)
	overlay_label = Label.new()
	overlay_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_label.add_theme_font_size_override("font_size", 26)
	box.add_child(overlay_label)
	overlay_button = Button.new()
	overlay_button.custom_minimum_size = Vector2(300, 70)
	overlay_button.add_theme_font_size_override("font_size", 24)
	overlay_button.pressed.connect(_on_overlay_button)
	box.add_child(overlay_button)


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


func _layout_buttons(all: Array) -> void:
	var s := get_viewport_rect().size
	var brake: Button = all[0]
	var gas: Button = all[1]
	var up: Button = all[2]
	var down: Button = all[3]
	brake.position = Vector2(20, s.y - 130)
	up.position = Vector2(210, s.y - 120)
	up.custom_minimum_size = Vector2(130, 90)
	up.add_theme_font_size_override("font_size", 18)
	down.position = Vector2(350, s.y - 120)
	down.custom_minimum_size = Vector2(130, 90)
	down.add_theme_font_size_override("font_size", 18)
	gas.position = Vector2(s.x - 210, s.y - 150)
	gas.custom_minimum_size = Vector2(190, 130)
