extends Control
## Fixed safe-zone HUD with scrollable modal bodies and persistent action footers.
var game
var font=preload('res://assets/action/body.ttf')
var title_font=preload('res://assets/action/title.ttf')
var panel:PanelContainer
var body:VBoxContainer
var footer:HBoxContainer
var heading:Label
var context:Button
var top_buttons:Array=[]
var page=''
var hero:Control
var scroll:ScrollContainer
var modal_tween:Tween
var dialogue_starts_boss=false
var notice:Label
const Icons=preload('res://action/icons.gd')
const INK=Color('#e6e9e2')
const MUTE=Color('#a6b8bb')
const GOLD=Color('#e5b77a')
const ICE=Color('#92d6d7')
func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mouse_filter=Control.MOUSE_FILTER_IGNORE
	var theme_resource=Theme.new();theme_resource.default_font=font;theme_resource.default_font_size=20;theme=theme_resource
	var actions=[['CORDÃO',func():game.switch_technique()],['DIÁRIO',func():diary()],['MAPA',func():map_menu()],['II',func():pause_menu()]]
	var icon_ids=['cordao','diary','map','pause']
	for i in range(actions.size()):
		var b=button(actions[i][0],actions[i][1]);b.icon=Icons.texture(icon_ids[i]);b.add_theme_constant_override('icon_max_width',23);b.add_theme_color_override('icon_normal_color',ICE);add_child(b);top_buttons.append(b)
	context=button('INTERAGIR',func():game.interact());context.position=Vector2(345,455);context.size=Vector2(260,54);add_child(context)
	var heal_button=button('CURAR',func():game.heal());heal_button.icon=Icons.texture('heal');heal_button.add_theme_constant_override('icon_max_width',20);add_child(heal_button);top_buttons.append(heal_button)
	notice=Label.new();notice.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;notice.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;notice.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;notice.mouse_filter=Control.MOUSE_FILTER_IGNORE;notice.add_theme_font_size_override('font_size',17);notice.add_theme_color_override('font_color',GOLD);add_child(notice)
	panel=PanelContainer.new();panel.position=Vector2(92,62);panel.size=Vector2(776,426)
	var style=StyleBoxFlat.new();style.bg_color=Color('#10232c');style.border_color=Color('#8c765b');style.set_border_width_all(2);style.set_corner_radius_all(3);style.content_margin_left=26;style.content_margin_right=26;style.content_margin_top=20;style.content_margin_bottom=18
	panel.add_theme_stylebox_override('panel',style);add_child(panel)
	var column=VBoxContainer.new();column.add_theme_constant_override('separation',14);panel.add_child(column)
	heading=Label.new();heading.add_theme_font_override('font',title_font);heading.add_theme_font_size_override('font_size',23);heading.add_theme_color_override('font_color',GOLD);column.add_child(heading)
	var separator=HSeparator.new();column.add_child(separator)
	scroll=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;column.add_child(scroll)
	body=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_theme_constant_override('separation',12);scroll.add_child(body)
	footer=HBoxContainer.new();footer.add_theme_constant_override('separation',12);footer.custom_minimum_size.y=56;column.add_child(footer)
	hero=Control.new();hero.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(hero)
	get_viewport().size_changed.connect(layout_controls);layout_controls()
func button(text:String,callback:Callable)->Button:
	var b=Button.new();b.text=text;b.custom_minimum_size=Vector2(100,56);b.focus_mode=Control.FOCUS_ALL
	b.add_theme_color_override('font_color',INK);b.add_theme_font_size_override('font_size',17)
	for state in ['normal','hover','pressed','focus']:
		var s=StyleBoxFlat.new();s.bg_color=Color('#19343e') if state=='normal' else Color('#31515a');s.border_color=GOLD if state=='focus' else Color('#58727a');s.set_border_width_all(1);s.set_corner_radius_all(3);s.content_margin_left=12;s.content_margin_right=12
		if state=='focus':s.draw_center=false
		b.add_theme_stylebox_override(state,s)
	b.button_down.connect(func():
		b.modulate=Color(1.18,1.18,1.12)
		if b.has_meta('press_tween'):
			var old=b.get_meta('press_tween')
			if old and old.is_running():old.kill()
		var tween=b.create_tween();b.set_meta('press_tween',tween);tween.tween_property(b,'modulate',Color.WHITE,.16)
		game.sound.effect('ui',.3)
	)
	b.pressed.connect(callback);return b
func clear_children(node:Node):
	for child in node.get_children():node.remove_child(child);child.queue_free()
func open_panel(title:String,id:String):
	game.modal=true
	if game.touch!=null:game.touch.release_all()
	page=id;clear_children(body);clear_children(footer);heading.text=title;hero.hide();panel.show();scroll.scroll_vertical=0
	layout_controls();update_status()
	if modal_tween and modal_tween.is_running():modal_tween.kill()
	panel.modulate.a=1 if game.preferences.reduced_motion else 0
	if not game.preferences.reduced_motion:modal_tween=create_tween();modal_tween.tween_property(panel,'modulate:a',1.0,.16)
func hide_panel():panel.hide();hero.hide();page='';queue_redraw()
func paragraph(text:String,color=INK):
	var l=Label.new();l.text=text;l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.add_theme_color_override('font_color',color);l.add_theme_font_size_override('font_size',24 if game.preferences.large_text else 21);body.add_child(l)
func action(text:String,callback:Callable,in_footer=false):
	var b=button(text,callback)
	if in_footer:footer.add_child(b);b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	else:body.add_child(b)
	if in_footer and footer.get_child_count()==1:call_deferred('focus_footer')
	return b
func close_action():action('VOLTAR',func():game.close_modal(),true)
func title():
	game.session_active=false
	open_panel('ENTRE MARGENS','title');panel.hide();hero.show();clear_children(hero)
	var y=282.0
	if game.has_save:
		var b=button('CONTINUAR TRAVESSIA',func():game.continue_game());b.set_meta('row',y);hero.add_child(b);y+=68
	var new_button=button('NOVA TRAVESSIA',func():new_game());new_button.set_meta('row',y);hero.add_child(new_button);y+=68
	var settings_button=button('AJUSTES',func():settings_menu(true));settings_button.set_meta('row',y);hero.add_child(settings_button)
	layout_controls()
func new_game():
	open_panel('Quem chega à margem?','new')
	paragraph('Você chegou à Várzea de Vidro para trabalhar com reparos. A primeira tarefa espera no porto.')
	var name_field=LineEdit.new();name_field.placeholder_text='Seu nome';name_field.max_length=24;name_field.custom_minimum_size.y=50;body.add_child(name_field)
	paragraph('Mova-se com o analógico. Segure ATQ para atacar, toque em TÉCNICA para usar Cordão e em ESQ para esquivar.\n\nAproxime-se de alguém para conversar.',MUTE)
	if game.has_save:paragraph('Uma nova travessia substituirá o progresso salvo.',GOLD)
	action('COMEÇAR',func():game.start_new(name_field.text),true)
	action('VOLTAR',func():title(),true)
func dialogue(o:Dictionary):
	dialogue_starts_boss=o.get('start_boss',false)
	open_panel(o.title,'dialogue');paragraph(o.get('text',''))
	if o.get('kind','')=='note':
		paragraph('Registro adicionado ao Diário. Até três cópias podem permanecer ancoradas.',ICE)
		action('ABRIR DIÁRIO',func():diary(),true)
	action('CONTINUAR',continue_dialogue,true)
func continue_dialogue():
	game.close_modal()
	if dialogue_starts_boss:game.combat.start_boss();dialogue_starts_boss=false
func puzzle(o:Dictionary):
	if o.get('puzzle_type','')=='circuit':circuit(o);return
	open_panel(o.title,'puzzle');paragraph(o.text)
	for i in range(o.options.size()):action(o.options[i],func():game.puzzle_answer(o,i))
	close_action()
func rest(o:Dictionary):
	open_panel(o.title,'rest')
	paragraph('Vigor e foco restaurados. Você leva pelo menos dois curativos. Progresso salvo.',ICE)
	paragraph('Reforço '+str(game.state.upgrades)+'/3 · '+str(game.state.parts)+' peças de cobre\nCada reforço concede +15 de vigor máximo e +3 de dano por golpe.')
	if game.state.upgrades<3:action('REFORÇAR EQUIPAMENTO · '+str(20+game.state.upgrades*15)+' peças',func():game.upgrade())
	paragraph('Lanternas reabastecem seus curativos. Encontros concluídos e descobertas permanecem depois de uma derrota.',MUTE)
	close_action()
func diary():
	open_panel('Diário de Âncoras · '+str(game.state.anchors.size())+'/3','diary')
	paragraph('Uma âncora preserva a versão registrada no momento em que você a prende. Soltar e prender depois de uma alteração não recupera a versão antiga.',MUTE)
	if game.state.evidence.is_empty():paragraph('Ainda não há registros. Converse com Lior, no porto.')
	for id in game.state.evidence:
		var o=game.catalog.object_by_id(id)
		if o.is_empty():continue
		var protected=id in game.state.anchors
		paragraph(('◆ ' if protected else '◇ ')+o.title,GOLD if protected else ICE)
		var original=o.get('anchor_text',o.text)
		var current=o.get('altered',original) if game.state.anomaly else original
		if protected:
			paragraph('ÂNCORA: '+game.state.anchor_records.get(id,original))
			if game.state.anomaly:paragraph('REGISTRO ATUAL: '+current,MUTE)
		else:paragraph(current)
		action('SOLTAR ÂNCORA' if protected else 'ANCORAR ESTA VERSÃO',func():game.anchor(id))
	close_action()
func map_menu():
	open_panel(game.current_room().name,'map')
	var map_view=preload('res://action/map.gd').new();map_view.game=game;map_view.custom_minimum_size=Vector2(680,240);body.add_child(map_view)
	paragraph('● Você    ◆ Objetivo pendente    ◇ Registro/descanso    » Saída',MUTE)
	var missing=game.catalog.required_remaining(game.state.room,game.state.done)
	for id in missing:
		var o=game.catalog.object_by_id(id)
		paragraph('• '+(o.title if not o.is_empty() else 'Desativar o regulador'),GOLD)
	if missing.is_empty():paragraph('Passagem liberada. Alcance a saída marcada.',ICE)
	close_action()
func pause_menu():
	open_panel('Uma pausa à margem','pause')
	paragraph('Tempo nesta travessia: '+time_label(game.state.elapsed)+'\nÁrea '+str(game.state.room+1)+'/6 · '+str(game.state.kills)+' mecanismos desativados · '+str(game.state.anchors.size())+' âncoras',MUTE)
	action('COMBATE ACESSÍVEL: '+('ATIVO' if game.state.assist else 'DESATIVADO'),func():game.state.assist=not game.state.assist;game.save_progress();pause_menu())
	action('TELA, SOM E ACESSIBILIDADE',func():settings_menu())
	action('COMO JOGAR',func():help_menu())
	action('SALVAR E CONTINUAR',func():game.save_progress();game.close_modal(),true)
func help_menu():
	open_panel('Ler o combate','help')
	paragraph('ATQ: combo de três golpes. Segurar o botão continua atacando. Acertos recuperam foco.\n\nTÉCNICA: CORDÃO interrompe inimigos próximos e desfaz projéteis. FRATURA atinge uma linha à frente e rompe escudos. Troque a técnica no alto da tela.\n\nESQ: atravesse um golpe durante a breve invulnerabilidade. Saia das marcas âmbar antes de elas dispararem.\n\nEscudos resistem a golpes frontais até perderem a postura. Ataque depois de sua investida ou use magia. Curativos podem ser usados durante o combate.\n\nControle: direcional esquerdo; X ataque, Y magia, A esquiva, B investigar, LB curar, RB técnica, Start pausa. Teclado: WASD, J, K, espaço, E, H, Q, Tab.')
	close_action()
func ending_choice():
	open_panel('O que a cidade vai sustentar?','choice')
	paragraph('A rede tenta conservar o desenho de um lugar anterior à comunidade. Dena espera sua decisão. A passarela pode voltar a existir, mas o calor precisa de um destino.')
	action('ISOLAR A REDE · reconstruir o aquecimento',func():game.finish('isolar'))
	action('MANTER O CONTORNO · assumir a manutenção',func():game.finish('contorno'))
	paragraph('As duas decisões preservam a comunidade. Cada uma cria um trabalho e um custo diferentes.',MUTE)
	close_action()
func epilogue():
	open_panel('A margem que permanece','epilogue')
	if game.state.ending=='isolar':
		paragraph('Você isola a Trama. Naquela noite, Dena abre o abrigo aquecido; famílias dividem cobertores e ferramentas. O inverno vai exigir novas caldeiras. A cidade escolhe reconstruir algo que consegue compreender.\n\nSena redesenha a passarela. Desta vez, deixa a corda presa à margem.')
	else:
		paragraph('Você mantém o fluxo pelo contorno. O calor continua chegando às casas, mas a rede precisará ser observada. Dena organiza turnos de manutenção; cada turno leva duas cópias do mesmo registro.\n\nSena redesenha a passarela. Lior deixa espaço para quem discordar do desenho.')
	if game.state.anchors.size()>=2:paragraph('Suas âncoras tornam públicas as versões contraditórias. O arquivo passa a guardar as divergências junto aos documentos.',ICE)
	else:paragraph('Faltam cópias preservadas para convencer todos. Lior registra a dúvida ao lado do seu testemunho.',ICE)
	paragraph('TRAVESSIA CONCLUÍDA\n'+time_label(game.state.elapsed)+' · '+str(game.state.evidence.size())+' registros · '+str(game.state.kills)+' mecanismos · '+str(game.state.deaths)+' recuos',GOLD)
	action('VOLTAR À CÂMARA',func():game.close_modal(),true)
	action('TÍTULO',func():title(),true)
func time_label(seconds:float)->String:return '%02d:%02d'%[int(seconds)/60,int(seconds)%60]
func update_status():
	if not is_instance_valid(context):return
	for b in top_buttons:b.visible=not game.modal
	top_buttons[0].text='CORDÃO' if game.state.technique=='cordao' else 'FRATURA'
	top_buttons[0].icon=Icons.texture(game.state.technique)
	top_buttons[4].text='CURAR · '+str(game.state.heals)
	var o=game.nearest_object()
	context.visible=not game.modal and not o.is_empty() and not game.nearby_threat()
	if not o.is_empty():
		context.text='SEGUIR »' if o.kind=='exit' else ('CONVERSAR' if o.get('npc',false) else ('DESCANSAR' if o.kind=='rest' else 'INVESTIGAR'))
	notice.visible=not game.modal and game.toast_timer>0
	notice.position.y=game.preferences.safe_rect(get_viewport()).position.y+(142 if game.combat.boss_active else 88)
	notice.text=game.toast_text;notice.modulate.a=minf(1,game.toast_timer/.3)
	queue_redraw()
func layout_controls():
	if not is_instance_valid(panel):return
	var safe=game.preferences.safe_rect(get_viewport());var w=safe.size.x
	var widths=[160,130,116,52];var x=safe.end.x
	for i in range(3,-1,-1):
		x-=widths[i];top_buttons[i].custom_minimum_size.x=widths[i];top_buttons[i].position=Vector2(x,safe.position.y);top_buttons[i].size=Vector2(widths[i],54);x-=8
	top_buttons[3].text='';top_buttons[3].tooltip_text='Pausa'
	top_buttons[4].position=Vector2(safe.position.x,safe.position.y+90);top_buttons[4].size=Vector2(150,54)
	notice.position=Vector2(safe.get_center().x-238,safe.position.y+88);notice.size=Vector2(476,58)
	context.size=Vector2(270,60);context.position=Vector2(safe.get_center().x-135,safe.end.y-65)
	panel.position=Vector2(safe.get_center().x-minf(800,w-48)/2,safe.position.y+12)
	panel.size=Vector2(minf(800,w-48),safe.size.y-24)
	if is_instance_valid(hero):
		hero.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		for b in hero.get_children():
			b.position=Vector2(safe.position.x+32,float(b.get_meta('row')));b.size=Vector2(365,58)
	queue_redraw()
func settings_menu(from_title=false):
	open_panel('Do seu jeito','settings')
	paragraph('Ajuste a distância da câmera e a leitura na sua tela.',MUTE)
	slider_row('CÂMERA',game.preferences.zoom,1.15,1.8,.05,func(v):game.preferences.zoom=v;game.apply_preferences(),true)
	slider_row('MÚSICA',game.preferences.music_volume,0,1,.05,func(v):game.preferences.music_volume=v;game.state.muted=false;game.apply_preferences())
	slider_row('EFEITOS',game.preferences.effects_volume,0,1,.05,func(v):game.preferences.effects_volume=v;game.state.muted=false;game.apply_preferences())
	action('TEXTO GRANDE  ·  '+('SIM' if game.preferences.large_text else 'NÃO'),func():game.preferences.large_text=not game.preferences.large_text;game.apply_preferences();settings_menu(from_title))
	action('MOVIMENTO REDUZIDO  ·  '+('SIM' if game.preferences.reduced_motion else 'NÃO'),func():game.preferences.reduced_motion=not game.preferences.reduced_motion;game.apply_preferences();settings_menu(from_title))
	action('CRÉDITOS',func():credits(from_title))
	action('VOLTAR',func():title() if from_title else pause_menu(),true)
func slider_row(text:String,value:float,low:float,high:float,step:float,callback:Callable,is_zoom=false):
	var row=HBoxContainer.new();row.add_theme_constant_override('separation',16);body.add_child(row)
	var label=Label.new();label.text=text;label.custom_minimum_size.x=124;label.add_theme_font_size_override('font_size',17);row.add_child(label)
	var slider=HSlider.new();slider.min_value=low;slider.max_value=high;slider.step=step;slider.value=value;slider.custom_minimum_size=Vector2(130,56);slider.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(slider)
	var number=Label.new();number.custom_minimum_size.x=76;number.text=str(int(round(value*100)))+('%' if not is_zoom else '%');row.add_child(number)
	slider.value_changed.connect(func(v):number.text=str(int(round(v*100)))+'%';callback.call(v))
func credits(from_title=false):
	open_panel('Quem deu forma à margem','credits')
	paragraph('ENTRE MARGENS
A Travessia Sem Nome',GOLD)
	paragraph('Mundo e história: universo de A Voz Sob o Gelo.

Pixel art: Shade — Puny Characters, Puny World e Puny Dungeon. Neve: Spring Spring.

Árvores e casas de inverno: Demetrius — LPC Winter Tiles, base de Lanea Zimmerman, agradecimento a William Thompson. CC BY 3.0. Recortes e cores adaptados na cena.
Licença: creativecommons.org/licenses/by/3.0/
Origem: opengameart.org/content/lpc-winter-tiles

Foley e efeitos: Kenney — Impact Sounds e RPG Audio.

Música da margem: yd — Short Loop: winter theme.
Música do Regulador: Emma_MA — Determined Pursuit.

Os recursos de Shade, Spring Spring, Kenney, yd e Emma_MA são CC0. Origens e licenças completas acompanham o projeto. Fontes: DejaVu Sans e DejaVu Serif.')
	action('VOLTAR',func():settings_menu(from_title),true)
func _draw():
	if game==null:return
	var size=get_viewport_rect().size;var safe=game.preferences.safe_rect(get_viewport())
	var left=safe.position.x;var top=safe.position.y
	if game.modal:
		draw_rect(Rect2(Vector2.ZERO,size),Color(.015,.045,.065,.88 if page!='title' else .60))
		if page=='title':draw_title(safe)
		return
	draw_rect(Rect2(left-8,top-6,280,84),Color(.025,.07,.095,.92))
	var text_size=16 if game.preferences.large_text else 14
	Icons.paint(self,'vigor',Vector2(left+9,top+11),Color('#d89379'),18)
	Icons.paint(self,'focus',Vector2(left+9,top+47),ICE,18)
	draw_string(font,Vector2(left+27,top+16),'VIGOR',HORIZONTAL_ALIGNMENT_LEFT,112,text_size,INK)
	draw_string(font,Vector2(left+150,top+16),str(int(maxf(0,game.state.health)))+' / '+str(int(game.state.max_health())),HORIZONTAL_ALIGNMENT_RIGHT,108,text_size,INK)
	draw_string(font,Vector2(left+27,top+52),'FOCO',HORIZONTAL_ALIGNMENT_LEFT,112,text_size,ICE)
	draw_string(font,Vector2(left+164,top+52),str(int(game.state.focus)),HORIZONTAL_ALIGNMENT_RIGHT,94,text_size,INK)
	draw_rect(Rect2(left+27,top+24,232,9),Color('#31414a'));draw_rect(Rect2(left+27,top+24,232*clampf(game.state.health/game.state.max_health(),0,1),9),Color('#cc8872'))
	draw_rect(Rect2(left+27,top+60,232,6),Color('#31414a'));draw_rect(Rect2(left+27,top+60,232*game.state.focus/100,6),ICE)
	if game.room_banner>0 and game.toast_timer<=0 and not game.combat.boss_active:
		var alpha=minf(1,game.room_banner)
		draw_string(title_font,Vector2(size.x/2-200,top+118),game.current_room().name,HORIZONTAL_ALIGNMENT_CENTER,400,23,Color(INK,alpha))
	if game.toast_timer>0:
		draw_rect(notice.get_rect().grow(6),Color(.025,.07,.095,.94*minf(1,game.toast_timer/.3)))
	var o=game.nearest_object()
	if context.visible:
		draw_rect(Rect2(size.x/2-196,safe.end.y-107,392,33),Color(.025,.07,.095,.88))
		draw_string(font,Vector2(size.x/2-185,safe.end.y-84),o.title,HORIZONTAL_ALIGNMENT_CENTER,370,18,INK)
	for e in game.combat.enemies:
		if e.kind!='boss':continue
		var bw=minf(420,size.x*.40);var bx=(size.x-bw)/2
		draw_rect(Rect2(bx,top+78,bw,50),Color(.025,.07,.095,.9))
		draw_string(font,Vector2(bx,top+97),'REGULADOR · ARO '+str(e.phase+1)+'/3',HORIZONTAL_ALIGNMENT_CENTER,bw,16,GOLD)
		draw_rect(Rect2(bx+12,top+110,bw-24,7),Color('#31414a'));draw_rect(Rect2(bx+12,top+110,(bw-24)*maxf(e.hp,0)/e.max_hp,7),GOLD)
func draw_title(safe:Rect2):
	var left=safe.position.x+32;var w=safe.size.x
	draw_string(font,Vector2(left,70),'A VOZ SOB O GELO',HORIZONTAL_ALIGNMENT_LEFT,-1,17,ICE)
	draw_string(title_font,Vector2(left,147),'Entre',HORIZONTAL_ALIGNMENT_LEFT,-1,62,INK)
	draw_string(title_font,Vector2(left,211),'Margens',HORIZONTAL_ALIGNMENT_LEFT,-1,62,INK)
	draw_line(Vector2(left,235),Vector2(left+62,235),GOLD,3)
	draw_string(font,Vector2(left+80,241),'A TRAVESSIA SEM NOME',HORIZONTAL_ALIGNMENT_LEFT,-1,16,GOLD)
	var center=Vector2(safe.position.x+w*.77,355)
	var sheet=preload('res://assets/sprites/characters/traveller.png')
	var pine=preload('res://assets/sprites/tiles/winter-trees.png')
	draw_set_transform(Vector2.ZERO,0,Vector2(1,.33));draw_circle(Vector2(center.x,center.y/.33),115,Color(.01,.03,.04,.4));draw_set_transform(Vector2.ZERO)
	draw_texture_rect_region(pine,Rect2(center-Vector2(102,293),Vector2(216,324)),Rect2(0,0,96,144),Color('#89a4b6'))
	draw_texture_rect_region(sheet,Rect2(center-Vector2(126,54),Vector2(112,112)),Rect2(0,0,32,32))
	draw_string(font,Vector2(center.x-152,444),'Toda margem guarda uma história.',HORIZONTAL_ALIGNMENT_CENTER,304,16,MUTE)

func circuit(o:Dictionary,pipes:Array=[]):
	var logic=preload('res://action/circuit.gd')
	if pipes.is_empty():pipes=logic.initial(abs(o.id.hash())%3)
	open_panel(o.title,'circuit')
	paragraph('Ligue a entrada no alto à esquerda à saída embaixo à direita. Toque para girar os tubos. O núcleo central deve ficar isolado.',MUTE)
	var grid=GridContainer.new();grid.columns=3;grid.add_theme_constant_override('h_separation',10);grid.add_theme_constant_override('v_separation',6);grid.size_flags_horizontal=Control.SIZE_SHRINK_CENTER;body.add_child(grid)
	for i in range(9):
		var b=button(('→ ' if i==0 else '')+logic.glyph(int(pipes[i]))+(' →' if i==8 else ''),func():
			pipes[i]=logic.rotate(int(pipes[i]));circuit(o,pipes)
		)
		b.custom_minimum_size=Vector2(130,47);b.add_theme_font_size_override('font_size',24);b.disabled=i==4;grid.add_child(b)
	action('TESTAR CIRCUITO',func():
		if logic.connected(pipes):game.puzzle_answer(o,int(o.solution))
		else:
			heading.text='Fluxo interrompido · confira as conexões'
	,true)
	close_action()

func focus_footer():
	if not is_instance_valid(panel) or not panel.visible or footer.get_child_count()==0:return
	var first=footer.get_child(0)
	if first.is_inside_tree() and first.is_visible_in_tree():first.grab_focus()
