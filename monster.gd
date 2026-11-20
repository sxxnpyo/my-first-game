extends Node2D
# 몬스터: 플레이어를 쫓아가고, 닿으면 피해를 줌. 칼에 맞으면 밀려나고 3번 맞으면 사라짐

signal killed

const RADIUS := 14.0
const MAX_HP := 3
const SPEED := 80.0

var hp := MAX_HP
var target                      # 쫓아갈 대상(플레이어)
var knockback := Vector2.ZERO
var flash := 0.0                # 맞았을 때 하얗게 번쩍이는 시간


func _ready() -> void:
	add_to_group("monsters")


func _process(delta: float) -> void:
	flash = maxf(flash - delta, 0.0)

	if target != null and is_instance_valid(target) and target.hp > 0:
		var to_player: Vector2 = target.global_position - global_position
		if to_player.length() > 1.0:
			position += to_player.normalized() * SPEED * delta
		if to_player.length() < RADIUS + target.BODY_RADIUS:
			target.take_damage(1)

	position += knockback * delta
	knockback = knockback.move_toward(Vector2.ZERO, 1200.0 * delta)
	queue_redraw()


func take_hit(amount: int, dir: Vector2) -> void:
	hp -= amount
	flash = 0.12
	knockback = dir * 400.0
	if hp <= 0:
		killed.emit()
		queue_free()


func _draw() -> void:
	var color := Color.WHITE if flash > 0.0 else Color(0.85, 0.25, 0.3)
	draw_circle(Vector2.ZERO, RADIUS, color)
	draw_circle(Vector2(-5, -3), 3.0, Color.BLACK)
	draw_circle(Vector2(5, -3), 3.0, Color.BLACK)
	# 체력바
	draw_rect(Rect2(-14, -24, 28, 4), Color(0.2, 0.2, 0.2))
	draw_rect(Rect2(-14, -24, 28.0 * hp / MAX_HP, 4), Color(0.4, 1.0, 0.4))
