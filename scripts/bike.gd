class_name Bike
extends Node2D
## Moto de trilha. No chão, as rodas seguem o terreno. Na ponta de uma rampa ela voa com gravidade,
## o piloto gira a moto no ar e a aterrissagem só dá certo se a moto estiver quase paralela ao chão.

enum State { GROUND, AIR, CRASHED }

const WHEEL_BASE := 302.0      # distância horizontal entre os eixos
const WHEEL_R := 72.0
const WHEEL_Y := 99.0          # altura dos eixos em relação ao centro do desenho
const MAX_SPEED := 360.0
const ACCEL := 240.0
const BRAKE := 420.0
const REVERSE_MAX := -120.0
const COAST := 90.0
const GRAVITY := 800.0
const ROT_SPEED := 5.5         # giro no ar, em rad/s
const LAND_TOLERANCE := 0.9    # diferença máxima (rad) entre a moto e o chão para aterrissar sem bater
const AIR_GRACE := 0.12        # logo depois de decolar, ignora o chão (a roda traseira ainda está na rampa)
const CRASH_TIME := 1.0
const START_X := 200.0

signal landed(clean: bool)

var state := State.GROUND
var distance := START_X        # x do eixo traseiro quando está no chão
var speed := 0.0
var wheel_angle := 0.0
var crashes := 0
var score := 0
var flips := 0
var air_rot := 0.0              # giro total no voo atual (rad); 2π = uma volta completa
var checkpoint_x := START_X
var jumps := 0
var flights: Array = []         # registro de cada voo (para teste e ajuste)
var _rear: Sprite2D
var _front: Sprite2D
var _mid := Vector2.ZERO       # centro entre os eixos (no ar)
var _vel := Vector2.ZERO
var _ang := 0.0
var _air_time := 0.0
var _crash_timer := 0.0


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
	_rear = _make_wheel(wheel_tex, wheel_scale)
	_front = _make_wheel(wheel_tex, wheel_scale)
	_place_ground()


func _make_wheel(tex: Texture2D, s: float) -> Sprite2D:
	var w := Sprite2D.new()
	w.texture = tex
	w.scale = Vector2.ONE * s
	add_child(w)
	return w


## Começa a fase do zero.
func reset(start_x: float) -> void:
	_build()
	state = State.GROUND
	distance = start_x
	checkpoint_x = start_x
	speed = 0.0
	crashes = 0
	score = 0
	flips = 0
	jumps = 0
	flights = []
	air_rot = 0.0
	_place_ground()


func air_angle() -> float:
	return _ang


## Um passo de tempo. gas = acelerar, brake = frear (ou dar ré), tilt = giro no ar (-1 empina, +1 inclina para a frente).
func update_motion(delta: float, gas: bool, brake: bool, tilt: float = 0.0) -> void:
	_build()
	match state:
		State.GROUND:
			_update_ground(delta, gas, brake)
		State.AIR:
			_update_air(delta, tilt)
		State.CRASHED:
			_crash_timer -= delta
			if _crash_timer <= 0.0:
				_respawn()


func _update_ground(delta: float, gas: bool, brake: bool) -> void:
	if gas:
		speed = minf(MAX_SPEED, speed + ACCEL * delta)
	elif brake:
		if speed > 0.0:
			speed = maxf(0.0, speed - BRAKE * delta)
		else:
			speed = maxf(REVERSE_MAX, speed - ACCEL * 0.5 * delta)
	else:
		speed = move_toward(speed, 0.0, COAST * delta)
	var old_rear_y := Terrain.ground_y(distance) - WHEEL_R
	var local := _rear_slope(distance)
	var prev_pos := position
	var prev_rot := rotation
	distance += speed * delta
	wheel_angle += speed * delta / WHEEL_R
	_place_ground()
	# decolagem: quando o chão some debaixo da roda de trás mais rápido do que a moto cairia, ela voa
	if speed > 60.0:
		var vel := Vector2(speed, speed * tan(local))
		var pred_y := old_rear_y + vel.y * delta + 0.5 * GRAVITY * delta * delta
		var ground_rear_y := Terrain.ground_y(distance) - WHEEL_R
		if ground_rear_y - pred_y > 2.0:
			_takeoff(vel, prev_pos, prev_rot)


## Inclinação do chão logo atrás da roda traseira (a da subida em que ela está).
func _rear_slope(xr: float) -> float:
	return atan2(Terrain.ground_y(xr) - Terrain.ground_y(xr - 30.0), 30.0)


## Decola com a posição e o ângulo do quadro anterior (a moto ainda estava na rampa).
func _takeoff(vel: Vector2, from_pos: Vector2, from_rot: float) -> void:
	state = State.AIR
	_vel = vel
	_ang = from_rot
	_mid = from_pos + Vector2(0, WHEEL_Y).rotated(_ang)
	_air_time = 0.0
	air_rot = 0.0
	flights.append({"x0": snappedf(distance, 1.0), "ang0": snappedf(_ang, 0.01), "vy": snappedf(vel.y, 1.0)})


func _update_air(delta: float, tilt: float) -> void:
	_air_time += delta
	_vel.y += GRAVITY * delta
	_mid += _vel * delta
	_ang += tilt * ROT_SPEED * delta
	air_rot += tilt * ROT_SPEED * delta
	wheel_angle += _vel.x * delta / WHEEL_R * 0.3   # a roda gira mais devagar no ar
	_place_air()
	if _air_time < AIR_GRACE:
		return
	var half := Vector2(WHEEL_BASE * 0.5, 0).rotated(_ang)
	var rear := _mid - half
	var front := _mid + half
	var hit_rear := rear.y + WHEEL_R >= Terrain.ground_y(rear.x)
	var hit_front := front.y + WHEEL_R >= Terrain.ground_y(front.x)
	if hit_rear or hit_front:
		_land(rear, front)


func _land(rear: Vector2, front: Vector2) -> void:
	var slope := atan2(Terrain.ground_y(front.x) - Terrain.ground_y(rear.x), WHEEL_BASE)
	var diff := absf(wrapf(_ang - slope, -PI, PI))
	var f: Dictionary = flights[flights.size() - 1]
	f["t"] = snappedf(_air_time, 0.01)
	f["ang1"] = snappedf(_ang, 0.01)
	f["slope"] = snappedf(slope, 0.01)
	f["x1"] = snappedf(rear.x, 1.0)
	if _air_time > 0.3:
		jumps += 1
	if diff > LAND_TOLERANCE:
		state = State.CRASHED
		_crash_timer = CRASH_TIME
		crashes += 1
		speed = 0.0
		air_rot = 0.0
		landed.emit(false)
		return
	state = State.GROUND
	distance = rear.x
	speed = maxf(0.0, _vel.dot(Vector2.from_angle(slope)))
	_place_ground()
	if _air_time > 0.5:
		var n := int(round(absf(air_rot) / TAU)) if absf(air_rot) > TAU * 0.8 else 0
		flips += n
		score += n * 500 + int(_air_time * 100.0)
	air_rot = 0.0
	landed.emit(true)


func _respawn() -> void:
	state = State.GROUND
	distance = checkpoint_x
	speed = 0.0
	_place_ground()


## No chão: as rodas nos pontos da pista e o corpo inclinado no mesmo ângulo.
## Se a roda da frente já está sobre um vazio (ponta da rampa), só a de trás apoia e a moto mantém o ângulo da subida.
func _place_ground() -> void:
	var xr := distance
	var xf := distance + WHEEL_BASE
	var cr := Vector2(xr, Terrain.ground_y(xr) - WHEEL_R)
	var cf := Vector2(xf, Terrain.ground_y(xf) - WHEEL_R)
	var ang := (cf - cr).angle()
	var local := _rear_slope(xr)
	if ang > local + 0.25:
		ang = local
		cf = cr + Vector2.from_angle(ang) * WHEEL_BASE
	var mid := (cr + cf) * 0.5
	var chord := (cf - cr).length()
	rotation = ang
	position = mid - Vector2(0, WHEEL_Y).rotated(ang)
	_rear.position = Vector2(-chord * 0.5, WHEEL_Y)
	_front.position = Vector2(chord * 0.5, WHEEL_Y)
	_rear.rotation = wheel_angle
	_front.rotation = wheel_angle


## No ar: o centro da moto voa e gira; as rodas ficam a uma distância fixa.
func _place_air() -> void:
	rotation = _ang
	position = _mid - Vector2(0, WHEEL_Y).rotated(_ang)
	_rear.position = Vector2(-WHEEL_BASE * 0.5, WHEEL_Y)
	_front.position = Vector2(WHEEL_BASE * 0.5, WHEEL_Y)
	_rear.rotation = wheel_angle
	_front.rotation = wheel_angle
