extends RefCounted
var state
var catalog
var inventory

func _init(s, c, i) -> void:
	state = s
	catalog = c
	inventory = i

func buy(id: String) -> String:
	var shop: Dictionary = catalog.tables.shops.neri.stock
	if not shop.has(id): return "Este item não está à venda."
	var price = int(catalog.tables.items[id].price)
	if int(state.data.stock_bought.get(id, 0)) >= int(shop[id]): return "Estoque de hoje esgotado. Neri repõe amanhã."
	if state.data.money < price: return "Fichas insuficientes. Coleta e pesca não exigem compra."
	if not inventory.exchange({}, {id:1}): return "Mochila cheia."
	state.data.money -= price
	state.data.stock_bought[id] = int(state.data.stock_bought.get(id, 0))+1
	return "Comprou %s por %d fichas." % [catalog.item_name(id), price]

func sell(id: String) -> String:
	if not catalog.tables.items.has(id): return "Item desconhecido."
	var value = int(catalog.tables.items[id].sell)
	if value <= 0: return "Evidências e estojos não são vendidos."
	if not inventory.exchange({id:1}, {}): return "Você não tem esse item."
	state.data.money += value
	return "Vendeu %s por %d fichas." % [catalog.item_name(id), value]

func craft(id: String) -> String:
	if not catalog.tables.recipes.has(id): return "Receita desconhecida."
	var recipe: Dictionary = catalog.tables.recipes[id]
	if not inventory.exchange(recipe.cost, recipe.result): return "Ingredientes insuficientes ou mochila cheia."
	return "Criou %s." % recipe.name
