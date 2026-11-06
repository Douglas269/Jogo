extends SceneTree
## Testes: a moto anda e fica no chão; salta nas rampas; aterrissa bem sem girar e bate se girar demais.
const Bike := preload("res://scripts/bike.gd")
const Terrain := preload("res://scripts/terrain.gd")
const Levels := preload("res://scripts/levels.gd")

var ok := true


func _check(cond: bool, msg: String) -> void:
	print(("  ok   " if cond else "  FALHA ") + msg)
	if not cond:
		ok = false


## Anda de gás até o primeiro salto terminar. tilt_air = giro aplicado só enquanto está no ar.
func _fly(tilt_air: float) -> Dictionary:
	var bike := Bike.new()
	root.add_child(bike)
	var max_air := 0.0
	var air := 0.0
	for i in 20 * 60:
		var tilt := tilt_air if bike.state == Bike.State.AIR else 0.0
		bike.update_motion(1.0 / 60.0, true, false, tilt)
		if bike.state == Bike.State.AIR:
			air += 1.0 / 60.0
			max_air = maxf(max_air, air)
		else:
			air = 0.0
		if bike.jumps >= 1 and bike.state != Bike.State.AIR and (bike.crashes > 0 or bike.distance > 1800.0):
			break
	print("   voos: ", bike.flights)
	var r := {"jumps": bike.jumps, "crashes": bike.crashes, "max_air": max_air, "state": bike.state, "x": bike.distance}
	bike.queue_free()
	return r


func _initialize() -> void:
	Terrain.set_ramps(Levels.DATA[0].ramps)
	print("1) no chão, as rodas tocam o pista antes da primeira rampa")
	var bike := Bike.new()
	root.add_child(bike)
	var worst := 0.0
	var worst_tilt := 0.0
	var frames_on_ground := 0
	for i in 20 * 60:
		bike.update_motion(1.0 / 60.0, true, false)
		if bike.state != Bike.State.GROUND or bike.distance > 650.0:
			break
		frames_on_ground += 1
		var rear := bike.to_global(bike._rear.position)
		var front := bike.to_global(bike._front.position)
		var g_r := Terrain.ground_y(bike.distance)
		var g_f := Terrain.ground_y(bike.distance + Bike.WHEEL_BASE)
		worst = maxf(worst, absf(rear.y - (g_r - Bike.WHEEL_R)))
		worst = maxf(worst, absf(front.y - (g_f - Bike.WHEEL_R)))
		worst_tilt = maxf(worst_tilt, absf(bike.rotation - atan2(g_f - g_r, Bike.WHEEL_BASE)))
	print("   quadros no chão: %d  desvio máximo: %.2f px  erro de inclinação: %.4f rad" % [frames_on_ground, worst, worst_tilt])
	_check(frames_on_ground > 100 and worst < 1.0 and worst_tilt < 0.01, "rodas no chão e moto inclinada como a pista")

	print("2) salto sem mexer: decola, voa e aterrissa sem bater")
	var a := _fly(0.0)
	print("   ", a)
	_check(int(a.jumps) >= 1 and float(a.max_air) > 0.3, "decolou na rampa e ficou no ar mais de 0,3 s")
	_check(int(a.crashes) == 0 and a.state == Bike.State.GROUND, "aterrissou sem bater e voltou ao chão")

	print("3) girando para a frente durante todo o salto: bate")
	var b := _fly(1.0)
	print("   ", b)
	_check(int(b.crashes) >= 1, "bateu por girar demais para a frente")

	print("4) empinando durante todo o salto: bate")
	var c := _fly(-1.0)
	print("   ", c)
	_check(int(c.crashes) >= 1, "bateu por girar demais para trás")

	print("5) soltando tudo, a moto para")
	var d := Bike.new()
	root.add_child(d)
	for i in 120:
		d.update_motion(1.0 / 60.0, true, false)
	for i in 900:
		d.update_motion(1.0 / 60.0, false, false)
	_check(absf(d.speed) < 1.0 and d.state == Bike.State.GROUND, "velocidade chegou a zero")
	print("RESULTADO: ", "OK" if ok else "FALHOU")
	quit(0 if ok else 1)
