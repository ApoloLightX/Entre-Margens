extends CanvasLayer
## All interfaces emit intents; services own mutations.
var game
var root: Control
var status: Label
var hint: Label
var toast_label: Label
var objective: Label
var panel: PanelContainer
var rows: VBoxContainer
var menu_scroll: ScrollContainer
var footer: HBoxContainer
var creation_page=0
var creation_draft={"name":"Viajante","pronouns":0,"origin":0,"coat":0,"hair":0}
const PRONOUNS=["elu","ela","ele"]
const ORIGINS=["Costa • coletor itinerante","Iqaluit • ajudante de cozinha","Tenhara • aprendiz de oficina","Jaci • auxiliar de medição"]
const COATS=["Âmbar • pele morena clara","Bruma • pele castanha","Urze • pele clara","Musgo • pele escura"]
const HAIRS=["Cabelo escuro curto","Cabelo castanho comprido","Cabelo grisalho curto"]
var mode = ""
var toast_time = 0.0
var fishing_time = 0.0
var fishing_bar: ProgressBar
var accessible = false
var mobile = OS.has_feature("android") or "--touch" in OS.get_cmdline_user_args()
var font = ThemeDB.fallback_font

func _ready() -> void:
	root=Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var theme=Theme.new()
	theme.default_font=font
	theme.default_font_size=26 if mobile else 18
	theme.set_color("font_color","Label",Color("#e2e9df"))
	theme.set_color("font_color","Button",Color("#e8e8d8"))
	for key in ["normal","hover","pressed","focus"]:
		var box=StyleBoxFlat.new()
		box.bg_color=Color("#36535c") if key=="normal" else Color("#647970")
		box.border_color=Color("#c5ac76")
		box.set_border_width_all(2 if key=="focus" else 1)
		box.set_corner_radius_all(6)
		box.content_margin_left=14;box.content_margin_right=14;box.content_margin_top=9;box.content_margin_bottom=9
		theme.set_stylebox(key,"Button",box)
	root.theme=theme
	var top=ColorRect.new(); top.color=Color("#1b3545");top.custom_minimum_size=Vector2(1280,90 if mobile else 60);top.size=Vector2(1280,90 if mobile else 60);root.add_child(top)
	status=Label.new();status.position=Vector2(26,24)
	status.add_theme_font_size_override("font_size",20 if mobile else 18);top.add_child(status)
	var nav=HBoxContainer.new();nav.position=Vector2(820 if mobile else 855,5);top.add_child(nav)
	for entry in [["Diário [J]","journal"],["Bolsa [I]","inventory"],["Pausa","pause"]]:
		var id:String=entry[1]
		var b=button(entry[0].replace(" [J]", "").replace(" [I]", "") if mobile else entry[0],func(): game.show_menu(id))
		nav.add_child(b)
	var bottom=ColorRect.new();bottom.color=Color("#1b3545");bottom.position=Vector2(0,710);bottom.size=Vector2(1280,90);root.add_child(bottom)
	hint=Label.new();hint.position=Vector2(26,10);hint.add_theme_font_size_override("font_size",19);bottom.add_child(hint)
	objective=Label.new();objective.position=Vector2(26,44);objective.add_theme_font_size_override("font_size",15);objective.modulate=Color("#b8cbbf");bottom.add_child(objective)
	toast_label=Label.new();toast_label.position=Vector2(25,666);toast_label.size=Vector2(1230,40);toast_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;toast_label.add_theme_color_override("font_color",Color("#f4deb1"));toast_label.add_theme_color_override("font_shadow_color",Color("#203544"));toast_label.add_theme_constant_override("shadow_offset_x",2);toast_label.add_theme_constant_override("shadow_offset_y",2);toast_label.z_index=100;toast_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;root.add_child(toast_label)

func button(text:String, action:Callable) -> Button:
	var b=Button.new();b.text=text;b.pressed.connect(action);b.custom_minimum_size.y=84 if mobile else 42
	return b

func _process(delta:float) -> void:
	if game==null: return
	status.text="ENTRE MARGENS    |    %s    |    VIDA %d   FOCO %d" % [game.clock.label(),game.state.data.health,int(game.state.data.focus)]
	var near:Dictionary=game.world.nearest()
	hint.text=("Agir: " if mobile else "[E] ")+str(near.name) if not near.is_empty() else ("Direcional: caminhar • ATQ: botão direito • AGIR: botão esquerdo" if mobile else "WASD / setas: caminhar • K/Enter: ataque • Espaço/1: magia • E: interagir")
	objective.text=game.objective_text()+("   •   ATQ K/Enter   •   MAGIA Espaço/1" if not mobile else "   •   ATQ: botão direito   •   MAGIA: menu")
	toast_time=maxf(0,toast_time-delta)
	toast_label.visible=toast_time>0
	if mode=="fishing" and is_instance_valid(fishing_bar):
		fishing_time+=delta
		fishing_bar.value=(sin(fishing_time*2.4)+1)*50

func toast(text:String) -> void:
	toast_label.text=text
	toast_time=7

func is_open() -> bool:
	return mode!=""

func close() -> void:
	if is_instance_valid(panel):
		root.remove_child(panel)
		panel.queue_free()
	mode=""
	fishing_bar=null
	menu_scroll=null
	footer=null

func begin(id:String,title:String,subtitle:String="") -> void:
	close()
	mode=id
	panel=PanelContainer.new()
	panel.position=Vector2(130,96) if mobile else Vector2(260,88)
	panel.size=Vector2(1020,595) if mobile else Vector2(760,600)
	var style=StyleBoxFlat.new();style.bg_color=Color("#213f4f");style.border_color=Color("#baaa85");style.set_border_width_all(2);style.set_corner_radius_all(12);style.content_margin_left=28;style.content_margin_right=28;style.content_margin_top=22;style.content_margin_bottom=22
	panel.add_theme_stylebox_override("panel",style)
	root.add_child(panel)
	var body=VBoxContainer.new()
	body.add_theme_constant_override("separation",12)
	panel.add_child(body)
	menu_scroll=ScrollContainer.new()
	menu_scroll.custom_minimum_size=Vector2(960,0) if mobile else Vector2(700,0)
	menu_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	menu_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(menu_scroll)
	rows=VBoxContainer.new();rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL;rows.add_theme_constant_override("separation",12);menu_scroll.add_child(rows)
	footer=HBoxContainer.new()
	footer.add_theme_constant_override("separation",12)
	body.add_child(footer)
	footer.visible=mobile
	if mobile:
		var previous=button("↑",func():scroll_menu(-250));previous.custom_minimum_size.x=92;previous.name="ScrollUp";footer.add_child(previous)
		var next=button("↓",func():scroll_menu(250));next.custom_minimum_size.x=92;next.name="ScrollDown";footer.add_child(next)
	add_text(title,30,Color("#edd6a6"))
	if subtitle!="": add_text(subtitle,16,Color("#a9c4c5"))

func add_text(text:String,size:int=18,color:Color=Color("#dce7df")) -> Label:
	var label=Label.new();label.text=text;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.custom_minimum_size.x=920 if mobile else 665;label.add_theme_font_size_override("font_size",maxi(size,24) if mobile else size);label.modulate=color;rows.add_child(label)
	return label

func add_button(text:String,action:Callable) -> Button:
	var b=button(text,action);rows.add_child(b)
	if not mobile and rows.get_children().filter(func(child): return child is Button).size()==1: b.call_deferred("grab_focus")
	return b

func scroll_menu(amount:int) -> void:
	if is_instance_valid(menu_scroll):
		menu_scroll.scroll_vertical+=amount

func footer_button(text:String,action:Callable) -> Button:
	var b=button(text,action)
	b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	footer.add_child(b)
	return b

func clear_footer() -> void:
	for child in footer.get_children():
		footer.remove_child(child)
		child.queue_free()
	footer.show()

func back() -> void:
	if mobile:footer_button("Voltar à vila",close)
	else:add_button("Voltar à vida na vila [Esc]",close)

func show_title() -> void:
	begin("title","ENTRE MARGENS","A VOZ SOB O GELO • uma história nova no mesmo universo")
	add_text("Faça deste lugar sua casa.",27,Color("#f1e4c7"))
	add_text("Uma enseada, uma casa vazia e seis vizinhos. Cultive junto às calhas, pesque, aprenda um ofício e guarde o que observar.")
	add_text("Protótipo Android 0.2.1 • arte e áudio provisórios.\nRitmo comprimido: o primeiro indício surge após três noites.\nEste recorte não reproduz a história do Livro I.",16)
	add_button("Começar uma nova vida",confirm_new_game)
	if FileAccess.file_exists("user://entre_margens.json") or FileAccess.file_exists("user://entre_margens.json.bak"):
		add_button("Continuar salvamento",func(): game.load_game())
	add_button("Sair",func(): game.get_tree().quit())

func confirm_new_game() -> void:
	if not FileAccess.file_exists("user://entre_margens.json"):
		show_creation()
		return
	begin("confirm_new", "Começar outra vida?", "Este protótipo usa um único slot.")
	add_text("Criar uma nova personagem substitui o salvamento principal. A cópia anterior fica como backup, mas poderá ser atualizada ao salvar novamente.")
	add_button("Criar personagem e substituir ao começar", show_creation)
	add_button("Voltar", show_title)

func show_creation() -> void:
	creation_draft={"name":"Viajante","pronouns":0,"origin":0,"coat":0,"hair":0}
	show_creation_page(0)

func creation_option(key:String,options:Array) -> OptionButton:
	var field=OptionButton.new()
	field.name=key.capitalize()+"Field"
	for value in options:field.add_item(value)
	field.selected=int(creation_draft[key])
	field.custom_minimum_size.y=84 if mobile else 48
	field.item_selected.connect(func(index:int):creation_draft[key]=index)
	rows.add_child(field)
	return field

func show_creation_page(page:int) -> void:
	creation_page=page
	begin("creation","Quem chega à margem?" if page==0 else "Como você chega?","1 de 2 • Nome, pronomes e origem" if page==0 else "2 de 2 • Aparência")
	clear_footer()
	if page==0:
		var name_field=LineEdit.new()
		name_field.name="NameField"
		name_field.placeholder_text="Seu nome"
		name_field.text=str(creation_draft.name)
		name_field.max_length=24
		name_field.custom_minimum_size.y=84 if mobile else 48
		name_field.text_changed.connect(func(value:String):creation_draft.name=value)
		name_field.text_submitted.connect(func(_value:String):
			name_field.release_focus()
			DisplayServer.virtual_keyboard_hide())
		rows.add_child(name_field)
		creation_option("pronouns",PRONOUNS)
		creation_option("origin",ORIGINS)
		footer_button("Voltar",show_title).name="CreationBack"
		footer_button("Avançar →",func():
			DisplayServer.virtual_keyboard_hide()
			show_creation_page(1)).name="CreationNext"
	else:
		add_text("%s • %s" % [str(creation_draft.name) if str(creation_draft.name)!="" else "Viajante",PRONOUNS[int(creation_draft.pronouns)]],26)
		creation_option("coat",COATS)
		creation_option("hair",HAIRS)
		add_text("A aparência é provisória. Sua origem não concede bônus nesta versão.",24)
		footer_button("← Voltar",func():show_creation_page(0)).name="CreationBack"
		footer_button("Começar minha vida",finish_creation).name="CreationConfirm"

func creation_back() -> void:
	if creation_page==1:show_creation_page(0)
	else:show_title()

func finish_creation() -> void:
	DisplayServer.virtual_keyboard_hide()
	game.new_game(str(creation_draft.name).strip_edges(),PRONOUNS[int(creation_draft.pronouns)],ORIGINS[int(creation_draft.origin)],int(creation_draft.coat),int(creation_draft.hair))

func show_intro() -> void:
	begin("intro","Uma casa para recomeçar","Várzea de Vidro • primeiro dia de Fresta")
	add_text("O último contrato terminou. Em vez de procurar outra estrada, você respondeu ao aviso da cooperativa: moradia para quem recuperasse uma casa e cuidasse de sua calha.")
	add_text("Dena deixou um bilhete: ‘O telhado segura. A água ainda não. Pegue fibras e pedras na margem. Depois, venha tomar caldo. O resto a gente conversa.’")
	add_text("A casa fica no telhado azul. Os leitos estão ao sul dela; a calha tem uma roda de cobre. A loja tem telhado verde. O cais e a galeria ficam a leste.")
	add_text("Use o direcional na tela para caminhar e Agir perto de pessoas ou objetos. Os menus pausam o relógio. Dentro de casa, use a cama para dormir.",16)
	back()

func show_inventory() -> void:
	begin("inventory","Bolsa e cultivo","%d / 60 unidades • evidências têm espaço protegido" % game.inventory.used())
	for id in game.state.data.inventory:
		var count=game.inventory.count(id)
		if count>0: add_text("%d × %s" % [count,game.catalog.item_name(id)],17)
	add_button("Plantar fungo-lanterna (precisa de calor)",func(): game.state.data.selected_crop="lantern";toast("Selecionado: fungo-lanterna");close())
	add_button("Plantar raiz-de-vidro (tolera frio)",func(): game.state.data.selected_crop="glassroot";toast("Selecionada: raiz-de-vidro");close())
	back()

func show_journal() -> void:
	begin("journal","Diário de Âncoras","O que foi visto não precisa concordar com o que está diante de você.")
	add_text("Vínculos protegidos: %d / 3. O estojo comporta três provas." % game.state.data.anchors.size(),16)
	if game.state.data.evidence.is_empty(): add_text("Nenhum registro ainda. Examine a placa no cais ou faça uma leitura na galeria.")
	for id in game.state.data.evidence:
		var e:Dictionary=game.state.data.evidence[id]
		add_text("Dia %d • %s\n%s" % [e.day,e.source,e.value],17)
		var key:String=id
		if id in game.state.data.anchors: add_text("PROTEGIDA • referência preservada",14,Color("#d9c58d"))
		else: add_button("Ancorar esta prova",func(): toast(game.memory.anchor(key));show_journal())
	add_text("Pessoas que você conhece",22)
	for id in game.state.data.relationships:
		add_text("%s • %s" % [game.catalog.tables.npcs[id].name,game.relationships.level(id)],16)
	add_text("Contratos",22)
	for id in game.catalog.tables.quests:
		add_text(("✓ " if id in game.state.data.claims else "• ")+game.catalog.tables.quests[id].title+" — "+game.catalog.tables.quests[id].description,16)
	add_button("Ver calendário e controles",show_help)
	back()

func show_help() -> void:
	begin("help","Calendário da margem","Fresta • Abertura • semana de seis dias")
	add_text("Calha → Pedra → Fio → Ofício → Cais → Mesa\nCada mês tem 24 dias. Este é um calendário local novo, não uma regra do Livro I.")
	add_text("Neste recorte: seis minutos de tempo ativo por dia. Cultivos crescem ao dormir. Calha ligada consome 1 musgo por noite. Leito seco dorme, sem morrer. Peixes: até seis capturas por dia.")
	add_text("Toque: direcional para caminhar; Agir para interagir. Menus no alto da tela. Arraste listas para rolar. Botão Voltar do Android fecha menus.\n\nWASD/setas ou analógico: caminhar\nE / A: interagir\nJ / Y: Diário • I / botão Menu: bolsa\nEspaço / X: recolher na pesca\nEsc / B: fechar ou pausar\nMouse: menus e interação próxima")
	add_text("O arco do recorte: registre a placa, faça uma medição na galeria e produza um estojo (2 fibras + 1 quartzo). Após três noites, compare de novo e escolha uma resposta no regulador.",16)
	add_text("Metas futuras: romances completos, outros bairros, pixel art final e calendário com festivais. Essas partes ainda não estão prontas.",15)
	back()

func show_dialogue(id:String) -> void:
	var npc:Dictionary=game.catalog.tables.npcs[id]
	begin("dialogue",npc.name,"%d invernos • %s • %s" % [npc.age,npc.home,game.relationships.level(id)])
	add_text(game.relationships.greeting(id),21)
	var choices:Array=game.catalog.tables.dialogues[id].choices
	for index in range(choices.size()):
		var chosen=index
		add_button(choices[index].text,func():
			var answer=game.relationships.answer(id,chosen)
			begin("answer",npc.name)
			add_text(answer,21)
			back())
	if id=="ivo" and "soup" not in game.state.data.claims:
		add_button("Entregar caldo de margem",func():toast(game.quests.claim("soup"));close())
	if id=="dena" and game.state.data.repaired and "calha" not in game.state.data.claims:
		add_button("Registrar a calha reparada",func():toast(game.quests.claim("calha"));close())
	back()

func show_shop() -> void:
	begin("trade","Venda da Margem","%d fichas • preços locais • estoque renovado a cada manhã" % game.state.data.money)
	add_text("Comprar",23)
	for id in game.catalog.tables.shops.neri.stock:
		var key:String=id
		add_button("%s — %d fichas" % [game.catalog.item_name(id),game.catalog.tables.items[id].price],func():toast(game.economy.buy(key));show_shop())
	add_text("Vender uma unidade",23)
	for id in game.state.data.inventory:
		if game.inventory.count(id)<=0 or int(game.catalog.tables.items[id].sell)<=0: continue
		var key:String=id
		add_button("%s (%d) — recebe %d" % [game.catalog.item_name(id),game.inventory.count(id),game.catalog.tables.items[id].sell],func():toast(game.economy.sell(key));show_shop())
	back()

func show_crafting() -> void:
	begin("craft","Bancada da Casa da Calha","Materiais só são consumidos quando a receita pode ser concluída.")
	for id in game.catalog.tables.recipes:
		var key:String=id
		var recipe:Dictionary=game.catalog.tables.recipes[id]
		var ingredients:Array[String]=[]
		for item in recipe.cost: ingredients.append("%d %s" % [recipe.cost[item],game.catalog.item_name(item)])
		add_text(recipe.name+"\n"+", ".join(ingredients),18)
		add_button("Criar "+recipe.name,func(): toast(game.economy.craft(key)))
	back()

func show_fishing(cave:bool) -> void:
	begin("fishing","Linha sobre a água","Observe a tensão. Recolha quando estiver entre 30 e 75.")
	fishing_time=0
	add_text("A água corre sob a camada antiga. Não há pressa: o peixe continua ali.",21)
	fishing_bar=ProgressBar.new();fishing_bar.custom_minimum_size=Vector2(650,42);fishing_bar.max_value=100;rows.add_child(fishing_bar)
	add_text("Faixa de recolhimento: 30–75. Espaço / X também recolhe.\nOpção sem timing disponível abaixo.",16)
	add_button("Recolher a linha",func(): game.finish_fishing(cave,false))
	add_button("Pescar sem timing (acessível)",func(): game.finish_fishing(cave,true))
	back()

func show_regulator() -> void:
	var message=game.memory.survey()
	begin("regulator","Regulador de Soleira","Uma referência isolada do circuito da vila")
	add_text(message,21)
	if game.state.data.ending!="":
		add_text("Sua decisão permanece: "+("retorno isolado" if game.state.data.ending=="isolate" else "medição mantida")+". Continue vivendo na vila, cultivando e conversando.")
	elif game.state.data.anomaly:
		add_text("Duas fontes e uma prova ancorada permitem calibrar com responsabilidade. Há quartzo nesta galeria e fibras na margem; a bancada fica em casa.",16)
		add_button("Isolar retorno — priorizar estabilidade do cais",func():game.resolve_mystery("isolate"))
		add_button("Manter medição — preservar fluxo e acompanhar",func():game.resolve_mystery("observe"))
	add_button("Abrir o Diário",show_journal)
	back()

func show_pause() -> void:
	begin("pause","Uma pausa à margem","O tempo está parado enquanto esta tela estiver aberta.")
	add_button("Retomar",close)
	add_button("Salvar agora",func():game.save_game())
	add_button("Carregar salvamento",func():game.load_game())
	add_button("Calendário e controles",show_help)
	add_button("Técnicas de magia",show_abilities)
	add_button("Áudio: ligar / desligar",func():game.audio.toggle();toast("Áudio "+("ligado" if game.audio.enabled else "desligado")))
	add_button("Menu inicial",func():game.save_game();show_title())
	add_button("Salvar e sair",func():if game.save_game(): game.get_tree().quit())

func show_abilities() -> void:
	begin("abilities","Técnicas da margem","Escolha a técnica ativa. O foco se recompõe com o tempo.")
	for id in ["cordao","fratura","silencio"]:
		var key:String=id
		var spec:Dictionary=game.abilities.spec(id)
		add_button(("✓ " if game.state.data.ability==id else "")+spec.name+" • %d foco • %0.1fs" % [spec.cost,spec.cooldown],func():game.state.data.ability=key;toast("Técnica ativa: "+spec.name);show_abilities())
		add_text({"cordao":"Arco curto de calor cristalizado. Interrompe ecos próximos.","fratura":"Linha de gelo que atravessa a distância e quebra formações.","silencio":"Pulso circular que cala uma área por um instante."}[id],16,Color("#b8cfd0"))
	back()
