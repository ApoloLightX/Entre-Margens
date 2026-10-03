extends RefCounted
const COSTS = {"lanca": 12.0, "onda": 30.0, "guarda": 20.0}
const COOLDOWNS = {"lanca": 0.35, "onda": 5.0, "guarda": 7.0}
static func can_cast(power: String, focus: float, remaining: float) -> bool:
	return COSTS.has(power) and focus >= COSTS[power] and remaining <= 0.0
static func damage_after_guard(damage: float, guarded: bool) -> float:
	return damage * 0.2 if guarded else damage
