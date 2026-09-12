# Entre Margens — revisão arquitetural do HUD responsivo (1.0.4)

Esta revisão sucede `18_LAYOUT_RESPONSIVO_ANCORAS_103.md`. A primeira migração para anchors estava visualmente correta nas capturas, mas ainda mantinha duas autoridades de posicionamento para os controles de toque: `action/hud.gd` e `action/touch.gd`. Isso tornava o resultado dependente da ordem dos callbacks de `Viewport.size_changed` e de uma sincronização `call_deferred()`. A 1.0.4 remove essa disputa em vez de apenas garantir que o HUD vença depois.

## Fonte única de layout

`action/hud.gd` é agora a única autoridade de layout responsivo:

- somente o HUD conecta `Viewport.size_changed`;
- `SafeArea` recebe a área segura calculada por `preferences.safe_rect()`;
- `HudMargins` (`MarginContainer`) concentra as margens de projeto uma única vez;
- `HudBounds` é a área interna à qual todos os grupos persistentes se ancoram;
- `touch.gd` não consulta viewport, `safe_rect`, resolução ou proporção de tela;
- `touch.gd.apply_layout()` recebe apenas centros/radius já resolvidos pelos `Control` nodes do HUD.

`touch.gd.layout_controls()` foi mantido apenas como uma delegação de compatibilidade para `hud.sync_touch_layout()`. Ele não contém cálculo próprio.

O raio do joystick também passou a ser fornecido pelo HUD em `apply_layout()`. A área de captura e o curso do knob são derivados desse raio em `touch.gd`, removendo os antigos `72`/`48` desacoplados sem mudar seus valores efetivos na build atual.

## Containers usados apenas onde eliminam acoplamento

Não foi adotada uma árvore inteira de containers nem o addon GameGUI. O sistema nativo do Godot já é suficiente para este HUD e evita nova dependência.

Foram usados containers em três pontos:

- `MarginContainer` para margem global do HUD;
- `VBoxContainer` para Vigor/Foco → gap → Curar, fazendo o segundo elemento depender estruturalmente do primeiro;
- `GridContainer` 2×2 para ESQ / TÉCNICA / ATQ, com uma célula vazia no canto superior esquerdo.

O topo direito continua `HBoxContainer`, como já era, mas sua largura passa a vir de `get_combined_minimum_size()` depois que os botões são criados. Assim não existe uma largura total presumida que possa divergir do tamanho mínimo real do conteúdo.

## Números mágicos removidos/reduzidos

Foram introduzidos/reutilizados tamanhos nomeados para:

- status;
- Curar;
- interação;
- notice;
- diâmetro do joystick;
- diâmetro dos botões de ação;
- offsets e altura do HUD do Regulador.

A posição normal do notice deriva de `STATUS_SIZE.y + GAP_BUTTONS`. Quando o Regulador está ativo, ela deriva de `BOSS_BAR_OFFSET_Y + BOSS_BAR_HEIGHT + NOTICE_BOSS_GAP`.

## Safe area real do sistema

A sugestão de usar `DisplayServer.get_display_safe_area()` já estava atendida antes desta revisão. `action/preferences.gd::safe_rect()` combina a margem própria do jogo com a área segura reportada pelo Android/iOS e converte de pixels físicos para o viewport lógico. Por isso essa lógica foi preservada e não duplicada dentro do HUD.

Referência: `https://docs.godotengine.org/en/4.5/classes/class_displayserver.html#class-displayserver-method-get-display-safe-area`.

## DPI, tamanho de toque e fonte

`ACTION_DIAMETER = 72` e `JOYSTICK_DIAMETER = 120` são unidades lógicas do viewport base 960×540, não pixels físicos crus. Com `canvas_items` + `expand`, o Godot escala esses elementos com a saída. O tamanho dos controles não foi alterado nesta correção para evitar uma mudança de ergonomia/input disfarçada de correção de layout.

As fontes também foram auditadas diretamente:

- `body.ttf`: DejaVu Sans;
- `title.ttf`: DejaVu Serif Bold;
- todos os caracteres portugueses usados no jogo (acentos, `ç`, travessões e símbolos de UI testados) existem no cmap;
- a licença DejaVu está em `assets/licenses/DEJAVU_LICENSE.txt` e referenciada em `assets/CREDITOS.md`.

Uma troca para themes normal/large ou uma preferência separada de controles grandes pode ser feita futuramente como trabalho de acessibilidade, mas não faz parte deste bugfix.

## Teste de resize dinâmico

`tests/test_mobile_ui.gd` não chama mais o cálculo antigo de `touch.gd` para "ajudar" o teste. Ele verifica que, após resize, os centros usados pelo input coincidem com os centros dos anchors do HUD.

Além dos alvos landscape 16:9, 19.5:9 e 20:9, a regressão faz uma sequência rápida:

`960×540 → 1200×540 → 540×960 → 1170×540 → 960×540`

O passo retrato é somente stress test arquitetural; o APK continua landscape-only.

Para cada etapa são verificadas também as interseções com a Gameplay Core. A suíte mobile passou com 137/137 checks.

## Referência oficial de múltiplas resoluções

A configuração existente continua alinhada à recomendação oficial do Godot para jogo mobile landscape: base única, `canvas_items`, `expand` e `Control` anchors/containers.

Referência: `https://docs.godotengine.org/en/4.5/tutorials/rendering/multiple_resolutions.html`.

## Arquivos alterados nesta revisão

- `godot/action/hud.gd`;
- `godot/action/touch.gd`;
- `godot/tests/test_mobile_ui.gd`;
- `godot/tests/test_presentation.gd` (remove chamada redundante ao layout do touch);
- `godot/export_presets.cfg` (1.0.4 / versionCode 13);
- `docs/19_LAYOUT_RESPONSIVO_REVIEW_104.md`.

Nenhum arquivo de combate, campanha, save ou balanceamento foi modificado.
