extends RefCounted
const CAPACITY = 60
var state
var catalog

func _init(s, c) -> void:
	state = s
	catalog = c

func count(id: String) -> int:
	return int(state.data.inventory.get(id, 0))

func used() -> int:
	var total = 0
	for id in state.data.inventory:
		if catalog.tables.items[id].kind != "evidence": total += count(id)
	return total

func can_pay(cost: Dictionary) -> bool:
	for id in cost:
		if count(id) < int(cost[id]): return false
	return true

func can_add(items: Dictionary, removed: Dictionary = {}) -> bool:
	var total = used()
	for id in removed:
		if catalog.tables.items[id].kind != "evidence": total -= int(removed[id])
	for id in items:
		if catalog.tables.items[id].kind != "evidence": total += int(items[id])
	return total <= CAPACITY

func exchange(cost: Dictionary, reward: Dictionary) -> bool:
	if not can_pay(cost) or not can_add(reward, cost): return false
	for id in cost:
		state.data.inventory[id] = count(id) - int(cost[id])
	for id in reward:
		state.data.inventory[id] = count(id) + int(reward[id])
	return true
