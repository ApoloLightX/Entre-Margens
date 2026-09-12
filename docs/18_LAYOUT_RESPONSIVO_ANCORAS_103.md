# Entre Margens — correção de layout responsivo por anchors (1.0.3)

Esta correção parte da build 1.0.3 polida e altera somente a arquitetura de posicionamento do HUD. Não há mudança de combate, progressão, conteúdo, save, áudio, câmera ou balanceamento. `data/action/combat.json` permanece byte a byte idêntico à base.

## Causa raiz

O HUD de combate combinava desenho manual em `_draw()` com reposicionamento por coordenadas calculadas em `layout_controls()`. Mesmo usando `safe_rect()`, cada grupo ainda dependia de posições absolutas recalculadas para a largura/altura corrente. Isso deixava o layout frágil fora da proporção de referência.

A documentação do Godot 4.5 recomenda `canvas_items` + `expand` com `Control` anchors para interfaces que precisam suportar múltiplos aspectos. A demo `Calinou/godot-multiple-resolutions` foi consultada apenas como referência de padrão: HUD preso às bordas, margens estáveis e centro de jogo preservado. Nenhum asset ou código externo foi copiado.

## Arquitetura nova

`action/hud.gd` agora possui um `SafeArea` `Control` em tela inteira. Este é o único nó que recebe offsets derivados de `preferences.safe_rect()`. Todos os grupos persistentes são filhos dele e usam anchors nativos do Godot:

- `StatusTopLeft`: `top-left`, contendo o desenho existente de Vigor/Foco em coordenadas locais do próprio Control;
- `Curar`: `top-left`, abaixo do status;
- `TopActions`: `top-right`, usando `HBoxContainer` para CORDÃO/técnica ativa, DIÁRIO, MAPA e pausa;
- `InteractionDock`: `bottom-center`;
- `JoystickBottomLeft`: `bottom-left`, como anchor invisível de 120 px;
- `ActionsBottomRight`: `bottom-right`, como anchor invisível da grade ATQ/TÉCNICA/ESQ.

O joystick e os botões de ação continuam sendo desenhados e recebendo input por `action/touch.gd`, sem alterar sua mecânica. Para respeitar o limite de arquivos desta tarefa, `hud.gd` sincroniza apenas `origin` e `buttons` do touch com os dois `Control` anchors. Assim a geometria visual e a hitbox usam a mesma fonte responsiva, enquanto `touch.gd` permanece inalterado.

## Constantes nomeadas

Foram removidos os números soltos usados no reposicionamento e introduzidas constantes no topo de `hud.gd`:

- `MARGIN_HUD_TOP`;
- `MARGIN_HUD_SIDE`;
- `MARGIN_HUD_BOTTOM`;
- `GAP_BUTTONS`;
- `GAP_TOP`;
- `GAP_DIALOG_CONTROLS`;
- `JOYSTICK_DIAMETER`;
- `ACTION_DIAMETER`;
- tamanhos nomeados de status, ações superiores e grade de toque.

As margens são aplicadas dentro do `safe_rect`. No viewport lógico de referência, a soma preserva os valores visuais efetivos da build anterior: 28 px laterais, 32 px no topo e 28 px embaixo.

## Gameplay Core

Para QA, `hud.gd` expõe `gameplay_core_rect()`: os 50% centrais da largura por 40% centrais da altura. Nenhum HUD persistente pode intersectar essa área. Essa região é uma regra de validação, não hitbox nem limitação de câmera.

## Proporções verificadas

A validação forçou três saídas físicas, mesmo com o APK continuando bloqueado em landscape:

- 1080×2340 (9:19.5, retrato de estresse);
- 1080×1920 (9:16, retrato de estresse);
- 1920×1080 (16:9, alvo horizontal).

Nos três casos, Vigor/Foco, Curar, ações de topo, dock de interação, joystick, ATQ, TÉCNICA e ESQ ficaram dentro do `safe_rect` e fora da Gameplay Core. As capturas foram renderizadas pelo projeto real no Godot 4.5.1.

Observação: o produto continua configurado como `landscape`. Os dois retratos existem apenas como teste arquitetural para expor dependências ocultas de coordenadas fixas.

## Arquivos alterados

- `godot/action/hud.gd`;
- `docs/18_LAYOUT_RESPONSIVO_ANCORAS_103.md`.

`action/world.gd` e `action/touch.gd` não precisaram ser alterados.

## Verificação executada

Godot 4.5.1:

- `tests/test_polish.gd`: 68/68;
- `tests/run_tests.gd`: 38/38;
- `tests/test_action.gd`: 230/230;
- `tests/test_action_draw.gd`: 54 callbacks;
- `tests/test_mobile_ui.gd`: 57/57;
- `tests/test_presentation.gd`: 87/87.

QA adicional de anchors: PASS nas três proporções acima para `inside_safe=true` e `core_clear=true` em todos os oito grupos persistentes avaliados.
