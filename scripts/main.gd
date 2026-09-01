extends Control
## Stage-C: 3 levels, image tiles, timer/score, next-level flow.

const TILE_GAP := 4.0
const BOARD_MAX := 320.0

@onready var _board: Control = $BoardWrap/Board
@onready var _hud: Label = $UI/HUD
@onready var _overlay: ColorRect = $UI/Overlay
@onready var _over_msg: Label = $UI/Overlay/VBox/Msg
@onready var _retry: Button = $UI/Overlay/VBox/Retry
@onready var _next_btn: Button = $UI/Overlay/VBox/Next
@onready var _shuffle_btn: Button = $UI/Shuffle
@onready var _level_row: HBoxContainer = $UI/LevelRow

var _level_id: int = 1
var _rows: int = 3
var _cols: int = 3
var _tiles: Array[int] = []
var _move_count: int = 0
var _solved: bool = false
var _tile_size: float = 100.0
var _started_msec: int = 0
var _source_tex: Texture2D
var _level_buttons: Array[Button] = []

func _ready() -> void:
	_source_tex = load("res://assets/miku_face.png") as Texture2D
	_retry.pressed.connect(_restart_level)
	_next_btn.pressed.connect(_on_next)
	_shuffle_btn.pressed.connect(_restart_level)
	_build_level_buttons()
	_start_level(1)

func _build_level_buttons() -> void:
	for c in _level_row.get_children():
		c.queue_free()
	_level_buttons.clear()
	for lv in PuzzleConfig.LEVELS:
		var b := Button.new()
		b.text = str(lv.label)
		b.custom_minimum_size = Vector2(88, 28)
		var id: int = int(lv.id)
		b.pressed.connect(func() -> void: _start_level(id))
		_level_row.add_child(b)
		_level_buttons.append(b)

func _start_level(id: int) -> void:
	_level_id = id
	var lv := PuzzleConfig.level(id)
	_rows = int(lv.rows)
	_cols = int(lv.cols)
	_tile_size = minf(BOARD_MAX / float(maxi(_rows, _cols)), 96.0)
	_tiles = PuzzleLogic.shuffle_solvable(_rows, _cols, int(lv.shuffle))
	_move_count = 0
	_solved = false
	_started_msec = Time.get_ticks_msec()
	_overlay.visible = false
	_rebuild_board()
	_update_hud()

func _restart_level() -> void:
	_start_level(_level_id)

func _on_next() -> void:
	if _level_id < 3:
		_start_level(_level_id + 1)
	else:
		_start_level(1)

func _elapsed_sec() -> int:
	return int((Time.get_ticks_msec() - _started_msec) / 1000)

func _remain_sec() -> int:
	var limit: int = int(PuzzleConfig.level(_level_id).time_limit)
	return maxi(0, limit - _elapsed_sec())

func _current_score() -> int:
	return PuzzleConfig.score(_level_id, _elapsed_sec(), _move_count)

func _process(_delta: float) -> void:
	if not _solved:
		_update_hud()

func _update_hud() -> void:
	_hud.text = "关卡 %d · %s\n剩余 %ds  分数 %d  步数 %d" % [
		_level_id,
		str(PuzzleConfig.level(_level_id).label),
		_remain_sec(),
		_current_score(),
		_move_count,
	]

func _rebuild_board() -> void:
	for c in _board.get_children():
		c.queue_free()
	var board_w := float(_cols) * _tile_size + float(_cols - 1) * TILE_GAP
	var board_h := float(_rows) * _tile_size + float(_rows - 1) * TILE_GAP
	_board.custom_minimum_size = Vector2(board_w, board_h)
	_board.size = Vector2(board_w, board_h)
	for i in _tiles.size():
		var val: int = _tiles[i]
		if val == 0:
			continue
		var r := i / _cols
		var c := i % _cols
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(_tile_size, _tile_size)
		btn.size = Vector2(_tile_size, _tile_size)
		btn.position = Vector2(float(c) * (_tile_size + TILE_GAP), float(r) * (_tile_size + TILE_GAP))
		btn.focus_mode = Control.FOCUS_NONE
		btn.text = ""
		# Piece `val` belongs at solved index (val - 1).
		var piece_idx := val - 1
		var pr := piece_idx / _cols
		var pc := piece_idx % _cols
		_style_tile(btn, pr, pc)
		var idx := i
		btn.pressed.connect(func() -> void: _on_tile(idx))
		_board.add_child(btn)

func _style_tile(btn: Button, piece_row: int, piece_col: int) -> void:
	var style := StyleBoxTexture.new()
	if _source_tex != null:
		var atlas := AtlasTexture.new()
		atlas.atlas = _source_tex
		var tw := float(_source_tex.get_width())
		var th := float(_source_tex.get_height())
		var cw := tw / float(_cols)
		var ch := th / float(_rows)
		atlas.region = Rect2(float(piece_col) * cw, float(piece_row) * ch, cw, ch)
		style.texture = atlas
	else:
		var flat := StyleBoxFlat.new()
		flat.bg_color = Color(0.35, 0.55, 0.85)
		flat.set_corner_radius_all(8)
		btn.add_theme_stylebox_override("normal", flat)
		return
	style.set_expand_margin_all(0)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)

func _on_tile(tile_index: int) -> void:
	if _solved:
		return
	if not PuzzleLogic.can_move(_tiles, _rows, _cols, tile_index):
		return
	_tiles = PuzzleLogic.move_tile(_tiles, _rows, _cols, tile_index)
	_move_count += 1
	_rebuild_board()
	_update_hud()
	if PuzzleLogic.is_solved(_tiles):
		_solved = true
		var elapsed := _elapsed_sec()
		var sc := _current_score()
		_over_msg.text = "通关！\n用时 %ds\n步数 %d\n得分 %d" % [elapsed, _move_count, sc]
		_next_btn.text = "下一关" if _level_id < 3 else "再来一轮"
		_overlay.visible = true
