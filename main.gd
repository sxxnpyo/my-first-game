extends Node2D
# 게임 전체를 관리: 플레이어 생성, 몬스터 소환, 화면 글자, 게임 오버

const PlayerScript = preload("res://player.gd")
const MonsterScript = preload("res://monster.gd")

const SPAWN_INTERVAL := 1.5  # 몬스터가 나오는 간격(초)

var player
var label: Label
var spawn_timer := 0.0
var kills := 0
var game_over := false


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.12, 0.14, 0.18))

	player = PlayerScript.new()
	player.position = get_viewport_rect().size / 2
	player.died.connect(_on_player_died)
	add_child(player)

	var ui := CanvasLayer.new()
	add_child(ui)
	label = Label.new()
	label.position = Vector2(16, 12)
	label.add_theme_font_size_override("font_size", 20)
	ui.add_child(label)


func _process(delta: float) -> void:
	if not game_over:
		spawn_timer -= delta
		if spawn_timer <= 0.0:
			spawn_monster()
			spawn_timer = SPAWN_INTERVAL

	var text := "HP: %d    Kills: %d\nMove: WASD   Attack: Left click / Space" % [player.hp, kills]
	if game_over:
		text += "\n\nGAME OVER - press R to restart"
	label.text = text


func spawn_monster() -> void:
	var m = MonsterScript.new()
	var size := get_viewport_rect().size
	match randi() % 4:
		0: m.position = Vector2(randf() * size.x, -20)
		1: m.position = Vector2(randf() * size.x, size.y + 20)
		2: m.position = Vector2(-20, randf() * size.y)
		_: m.position = Vector2(size.x + 20, randf() * size.y)
	m.target = player
	m.killed.connect(_on_monster_killed)
	add_child(m)


func _on_monster_killed() -> void:
	kills += 1


func _on_player_died() -> void:
	game_over = true


func _unhandled_input(event: InputEvent) -> void:
	if game_over and event is InputEventKey and event.pressed and event.physical_keycode == KEY_R:
		get_tree().reload_current_scene()
