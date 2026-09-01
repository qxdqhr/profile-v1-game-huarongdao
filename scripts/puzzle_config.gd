class_name PuzzleConfig
extends RefCounted

## Align with DEFAULT_HUARONGDAO_LEVEL_CONFIGS + TIME_LIMIT_MAP.

const LEVELS: Array[Dictionary] = [
	{"id": 1, "label": "难度 1", "rows": 3, "cols": 3, "shuffle": 60, "time_limit": 180},
	{"id": 2, "label": "难度 2", "rows": 4, "cols": 4, "shuffle": 110, "time_limit": 240},
	{"id": 3, "label": "难度 3", "rows": 5, "cols": 5, "shuffle": 180, "time_limit": 300},
]

static func level(id: int) -> Dictionary:
	for lv in LEVELS:
		if int(lv.id) == id:
			return lv
	return LEVELS[0]

static func score(level_id: int, elapsed_sec: int, moves: int) -> int:
	var max_score := 1200 + level_id * 500
	return maxi(0, max_score - elapsed_sec * 6 - moves * 4)
