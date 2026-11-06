extends SceneTree
## Testes das fases: um piloto automático completa cada fase sem bater, e dá para fazer giros.
const Bike := preload("res://scripts/bike.gd")
const Terrain := preload("res://scripts/terrain.gd")
const Levels := preload("res://scripts/levels.gd")

var ok := true


func _check(cond: bool, msg: String) -> void:
	print(("  ok   " if cond else "  FALHA ") + msg)
	if not cond:
		ok = false


## Joga a fase inteira. flip_mode: 0 só estabiliza no ar; -1 dá um mortal para trás; 1 dá um mortal para a frente.
func _play(i: int, flip_mode: int) -> Dictionary:
	var lv: Dictionary = Levels.DATA[i]
	Terrain.set_ramps(lv.ramps)
	var bike := Bike.new()
	root.add_child(bike)
	bike.reset(Bike.START_X)
	var t := 0.0
	var finished := false
	while t < 200.0 and bike.crashes == 0:
		var tilt := 0.0
		if bike.state == Bike.State.AIR:
			var a := bike.air_angle()
			# o mortal só é tentado no último salto (o maior); nos outros, só estabiliza
			var jumps_in_level: int = lv.ramps.filter(func(r): return str(r.type) == "jump").size()
			var try_flip: bool = flip_mode != 0 and bike.flights.size() == jumps_in_level
			var need := TAU - 0.5 if flip_mode < 0 else TAU + 0.3
			if try_flip and absf(bike.air_rot) < need:
				tilt = float(flip_mode)
			else:
				var diff := wrapf(a, -PI, PI)
				tilt = clampf(-diff * 3.0, -1.0, 1.0)
		bike.update_motion(1.0 / 60.0, true, false, tilt)
		t += 1.0 / 60.0
		if bike.state == Bike.State.GROUND and bike.distance + Bike.WHEEL_BASE >= float(lv.length):
			finished = true
			break
	var r := {"finished": finished, "crashes": bike.crashes, "time": snappedf(t, 0.1), "score": bike.score, "flips": bike.flips, "jumps": bike.jumps, "flights": bike.flights.size()}
	bike.queue_free()
	return r


func _initialize() -> void:
	for i in Levels.count():
		print("Fase %d (%s): piloto automático sem manobras" % [i + 1, Levels.DATA[i].name])
		var r := _play(i, 0)
		print("   ", r)
		_check(r.finished and int(r.crashes) == 0, "completou sem bater")
	print("Giros: mortal para trás e para a frente na fase mais difícil")
	var last := Levels.count() - 1
	var back := _play(last, -1)
	print("   para trás:  ", back)
	var front := _play(last, 1)
	print("   para frente:", front)
	_check(int(back.flips) >= 1, "consegue um mortal para trás")
	_check(int(front.flips) >= 1, "consegue um mortal para a frente")
	_check(Levels.stars(0, 5000, 2000) == 3 and Levels.stars(1, 0, 2000) == 2 and Levels.stars(5, 0, 0) == 1, "regra das estrelas")
	print("RESULTADO: ", "OK" if ok else "FALHOU")
	quit(0 if ok else 1)
