class_name Levels
extends RefCounted
## Fases. Cada fase é uma sequência de rampas cada vez maiores. Chegar ao fim conclui a fase;
## bater só volta ao último ponto seguro. Estrelas: 1 por concluir, 2 com no máximo 1 batida,
## 3 sem bater e com a pontuação mínima (giros no ar).

const DATA := [
	{
		"name": "Treino",
		"length": 3400.0,
		"target": 0,
		"ramps": [
			{"type": "jump", "x": 900.0, "len": 150.0, "h": 90.0},
			{"type": "hill", "x": 1250.0, "len": 420.0, "h": 70.0},
			{"type": "jump", "x": 2100.0, "len": 170.0, "h": 120.0},
			{"type": "hill", "x": 2500.0, "len": 460.0, "h": 90.0},
		],
	},
	{
		"name": "Rampas altas",
		"length": 4600.0,
		"target": 600,
		"ramps": [
			{"type": "jump", "x": 900.0, "len": 200.0, "h": 150.0},
			{"type": "hill", "x": 1350.0, "len": 520.0, "h": 110.0},
			{"type": "jump", "x": 2300.0, "len": 230.0, "h": 190.0},
			{"type": "hill", "x": 2800.0, "len": 560.0, "h": 130.0},
			{"type": "jump", "x": 3600.0, "len": 240.0, "h": 220.0},
			{"type": "hill", "x": 4150.0, "len": 600.0, "h": 150.0},
		],
	},
	{
		"name": "Mestre das manobras",
		"length": 5600.0,
		"target": 2000,
		"ramps": [
			{"type": "jump", "x": 900.0, "len": 240.0, "h": 200.0},
			{"type": "hill", "x": 1450.0, "len": 620.0, "h": 140.0},
			{"type": "jump", "x": 2500.0, "len": 280.0, "h": 260.0},
			{"type": "hill", "x": 3100.0, "len": 680.0, "h": 170.0},
			{"type": "jump", "x": 4000.0, "len": 300.0, "h": 300.0},
			{"type": "hill", "x": 4650.0, "len": 760.0, "h": 190.0},
		],
	},
]


static func count() -> int:
	return DATA.size()


static func stars(crashes: int, score: int, target: int) -> int:
	if crashes == 0 and score >= target:
		return 3
	if crashes <= 1:
		return 2
	return 1
