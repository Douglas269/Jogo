class_name Bike
extends Node2D
## Moto de trilha. As duas rodas ficam sobre o chão e a moto inclina conforme a subida ou descida.

const WHEEL_BASE := 302.0      # distância entre os eixos
const WHEEL_R := 72.0          # raio da roda
const WHEEL_Y := 99.0          # altura dos eixos em relação ao centro do desenho
const MAX_SPEED := 340.0
const ACCEL := 240.0
const BRAKE := 420.0
const REVERSE_MAX := -120.0
const COAST := 90.0            # atrito quando ninguém aperta nada

var distance := 0.0            # posição do eixo traseiro na pista
var speed := 0.0
var wheel_angle := 0.0
var _rear: Sprite2D
var _front: Sprite2D


func _ready() -> void:
	_build()


## Monta o desenho da moto uma única vez (também é chamado antes do primeiro movimento).
func _build() -> void:
	if _rear != null:
		return
	var body := Sprite2D.new()
	body.texture = load("res://assets/moto_amarela.png")
	body.scale = Vector2.ONE * (430.0 / 451.0)
	body.position = Vector2(6.7, 0)
	add_child(body)
	var wheel_tex: Texture2D = load("res://assets/roda_amarela.png")
	var wheel_scale := WHEEL_R * 2.0 / float(wheel_tex.get_width())
	_rear = _make_wheel(wheel_tex, wheel_scale, Vector2(-WHEEL_BASE * 0.5, WHEEL_Y))
	_front = _make_wheel(wheel_tex, wheel_scale, Vector2(WHEEL_BASE * 0.5, WHEEL_Y))
	_place()


func _make_wheel(tex: Texture2D, s: float, pos: Vector2) -> Sprite2D:
	var w := Sprite2D.new()
	w.texture = tex
	w.scale = Vector2.ONE * s
	w.position = pos
	add_child(w)
	return w


## Anda um passo de tempo. gas = acelerar, brake = frear (e dar ré se parado).
func update_motion(delta: float, gas: bool, brake: bool) -> void:
	_build()
	if gas:
		speed = minf(MAX_SPEED, speed + ACCEL * delta)
	elif brake:
		if speed > 0.0:
			speed = maxf(0.0, speed - BRAKE * delta)
		else:
			speed = maxf(REVERSE_MAX, speed - ACCEL * 0.5 * delta)
	else:
		speed = move_toward(speed, 0.0, COAST * delta)
	distance += speed * delta
	wheel_angle += speed * delta / WHEEL_R
	_place()


## Coloca a moto sobre o terreno: rodas nos pontos do chão e corpo inclinado no mesmo ângulo.
func _place() -> void:
	var xr := distance
	var xf := distance + WHEEL_BASE
	var cr := Vector2(xr, Terrain.ground_y(xr) - WHEEL_R)
	var cf := Vector2(xf, Terrain.ground_y(xf) - WHEEL_R)
	var ang := (cf - cr).angle()
	var mid := (cr + cf) * 0.5
	var chord := (cf - cr).length()   # distância entre os eixos medida na inclinação
	rotation = ang
	position = mid - Vector2(0, WHEEL_Y).rotated(ang)
	_rear.position = Vector2(-chord * 0.5, WHEEL_Y)
	_front.position = Vector2(chord * 0.5, WHEEL_Y)
	_rear.rotation = wheel_angle
	_front.rotation = wheel_angle
