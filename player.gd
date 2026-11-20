extends Node2D
# 플레이어: WASD로 이동, 마우스 방향으로 칼 휘두르기

signal died

const SPEED := 220.0              # 이동 속도
const BODY_RADIUS := 16.0
const SWORD_LENGTH := 70.0        # 칼 길이(공격 범위)
const SWING_TIME := 0.2           # 한 번 휘두르는 데 걸리는 시간(초)
const SWING_ARC := deg_to_rad(120.0)  # 휘두르는 각도
const ATTACK_COOLDOWN := 0.35     # 다음 공격까지 기다리는 시간(초)
const MAX_HP := 5

var hp := MAX_HP
var facing := Vector2.RIGHT
var swinging := false
var swing_timer := 0.0
var cooldown := 0.0
var hurt_timer := 0.0             # 맞은 뒤 잠깐 무적인 시간
var hit_this_swing: Array = []    # 이번 휘두르기에 이미 맞은 몬스터


func _process(delta: float) -> void:
	cooldown = maxf(cooldown - delta, 0.0)
	hurt_timer = maxf(hurt_timer - delta, 0.0)

	if hp > 0:
		move(delta)
		if swinging:
			update_swing(delta)

	queue_redraw()


func move(delta: float) -> void:
	var dir := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_A): dir.x -= 1
	if Input.is_physical_key_pressed(KEY_D): dir.x += 1
	if Input.is_physical_key_pressed(KEY_W): dir.y -= 1
	if Input.is_physical_key_pressed(KEY_S): dir.y += 1
	if dir != Vector2.ZERO:
		position += dir.normalized() * SPEED * delta
	position = position.clamp(Vector2.ZERO, get_viewport_rect().size)
	if not swinging:
		var to_mouse := get_global_mouse_position() - global_position
		if to_mouse.length() > 1.0:
			facing = to_mouse.normalized()


func _unhandled_input(event: InputEvent) -> void:
	if hp <= 0:
		return
	var clicked := event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	var space := event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_SPACE
	if (clicked or space) and cooldown <= 0.0:
		start_swing()


func start_swing() -> void:
	swinging = true
	swing_timer = 0.0
	cooldown = ATTACK_COOLDOWN
	hit_this_swing.clear()
	var to_mouse := get_global_mouse_position() - global_position
	if to_mouse.length() > 1.0:
		facing = to_mouse.normalized()


func update_swing(delta: float) -> void:
	swing_timer += delta
	var base := facing.angle()
	var monsters: Array = get_tree().get_nodes_in_group("monsters")
	for m in monsters:
		if m in hit_this_swing:
			continue
		var to_m: Vector2 = m.global_position - global_position
		var in_range: bool = to_m.length() <= SWORD_LENGTH + m.RADIUS
		var angle_gap: float = absf(wrapf(to_m.angle() - base, -PI, PI))
		if in_range and angle_gap <= SWING_ARC / 2.0:
			hit_this_swing.append(m)
			m.take_hit(1, to_m.normalized())
	if swing_timer >= SWING_TIME:
		swinging = false


func take_damage(amount: int) -> void:
	if hurt_timer > 0.0 or hp <= 0:
		return
	hp -= amount
	hurt_timer = 0.8
	if hp <= 0:
		died.emit()


func _draw() -> void:
	var body_color := Color(0.3, 0.6, 1.0)
	if hp <= 0:
		body_color = Color(0.4, 0.4, 0.4)
	elif hurt_timer > 0.0 and int(hurt_timer * 10.0) % 2 == 0:
		body_color = Color.WHITE
	draw_circle(Vector2.ZERO, BODY_RADIUS, body_color)
	draw_circle(facing * 8.0, 4.0, Color.WHITE)  # 바라보는 방향 표시

	if swinging:
		var t := swing_timer / SWING_TIME
		var start_angle := facing.angle() - SWING_ARC / 2.0
		var a := start_angle + SWING_ARC * t
		var dir := Vector2.from_angle(a)
		# 휘두른 궤적
		draw_arc(Vector2.ZERO, SWORD_LENGTH * 0.8, start_angle, a, 16, Color(1, 1, 1, 0.3), 12.0)
		# 칼날
		draw_line(dir * BODY_RADIUS, dir * SWORD_LENGTH, Color(0.9, 0.92, 0.98), 5.0)
