extends SceneTree
const Rules = preload("res://scripts/rules.gd")
func _initialize():
	assert(Rules.can_cast("onda", 30, 0))
	assert(not Rules.can_cast("onda", 29, 0))
	assert(not Rules.can_cast("lanca", 100, 0.1))
	assert(not Rules.can_cast("desconhecido", 100, 0))
	assert(Rules.damage_after_guard(25, true) == 5)
	assert(Rules.damage_after_guard(25, false) == 25)
	print("6 verificações de custo, recarga e defesa passaram")
	quit()
