extends SceneTree
## Teste do passo 1: a moto anda, as rodas ficam sobre o chão e o corpo acompanha a inclinação.
const Bike := preload("res://scripts/bike.gd")
const Terrain := preload("res://scripts/terrain.gd")


func _initialize() -> void:
	var bike := Bike.new()
	root.add_child(bike)
	var ok := true
	# 1) gás faz a moto andar
	for i in 600:
		bike.update_motion(1.0 / 60.0, true, false)
	print("após 10s de gás: distância=%.0f velocidade=%.0f" % [bike.distance, bike.speed])
	ok = ok and bike.distance > 1000.0 and bike.speed > 300.0
	# 2) em cada passo, as duas rodas tocam o chão (erro menor que 1 px)
	var worst := 0.0
	var worst_tilt := 0.0
	for i in 600:
		bike.update_motion(1.0 / 60.0, true, false)
		var rear := bike.to_global(bike._rear.position)
		var front := bike.to_global(bike._front.position)
		var r_bottom := rear.y + Bike.WHEEL_R
		var f_bottom := front.y + Bike.WHEEL_R
		var g_r := Terrain.ground_y(bike.distance)
		var g_f := Terrain.ground_y(bike.distance + Bike.WHEEL_BASE)
		worst = maxf(worst, absf(rear.y - (g_r - Bike.WHEEL_R)))
		worst = maxf(worst, absf(front.y - (g_f - Bike.WHEEL_R)))
		worst_tilt = maxf(worst_tilt, absf(bike.rotation - atan2(g_f - g_r, Bike.WHEEL_BASE)))
	print("maior desvio do chão: %.2f px | maior erro de inclinação: %.4f rad" % [worst, worst_tilt])
	ok = ok and worst < 1.0 and worst_tilt < 0.01
	# 3) freio para a moto; soltando tudo, o atrito a deixa parada
	for i in 60:
		bike.update_motion(1.0 / 60.0, false, true)
	print("após 1s de freio: velocidade=%.1f" % bike.speed)
	ok = ok and bike.speed < 0.0 + 1.0
	for i in 900:
		bike.update_motion(1.0 / 60.0, false, false)
	print("soltando tudo por 15s: velocidade=%.1f" % bike.speed)
	ok = ok and absf(bike.speed) < 1.0
	print("RESULTADO: ", "OK" if ok else "FALHOU")
	quit(0 if ok else 1)
