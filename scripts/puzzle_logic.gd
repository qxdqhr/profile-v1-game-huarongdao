class_name PuzzleLogic
extends RefCounted

static func build_solved(rows: int, cols: int) -> Array[int]:
	var total := rows * cols
	var arr: Array[int] = []
	for i in total:
		arr.append((i + 1) % total)
	return arr

static func is_solved(tiles: Array[int]) -> bool:
	for i in tiles.size():
		if tiles[i] != (i + 1) % tiles.size():
			return false
	return true

static func can_move(tiles: Array[int], rows: int, cols: int, tile_index: int) -> bool:
	var blank := tiles.find(0)
	if blank < 0 or tile_index < 0 or tile_index >= tiles.size():
		return false
	var br := blank / cols
	var bc := blank % cols
	var tr := tile_index / cols
	var tc := tile_index % cols
	return absi(br - tr) + absi(bc - tc) == 1

static func move_tile(tiles: Array[int], rows: int, cols: int, tile_index: int) -> Array[int]:
	if not can_move(tiles, rows, cols, tile_index):
		return tiles.duplicate()
	var next: Array[int] = tiles.duplicate()
	var blank := next.find(0)
	var blank_val: int = next[blank]
	var tile_val: int = next[tile_index]
	next[blank] = tile_val
	next[tile_index] = blank_val
	return next

static func shuffle_solvable(rows: int, cols: int, steps: int = 80) -> Array[int]:
	var tiles := build_solved(rows, cols)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for _i in steps:
		var blank := tiles.find(0)
		var br := blank / cols
		var bc := blank % cols
		var candidates: Array[int] = []
		var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
		for d in dirs:
			var nr := br + d.x
			var nc := bc + d.y
			if nr >= 0 and nr < rows and nc >= 0 and nc < cols:
				candidates.append(nr * cols + nc)
		if candidates.is_empty():
			continue
		var idx: int = candidates[rng.randi_range(0, candidates.size() - 1)]
		var blank_val: int = tiles[blank]
		var idx_val: int = tiles[idx]
		tiles[blank] = idx_val
		tiles[idx] = blank_val
	return tiles
