# Entre Margens — A Travessia Sem Nome

> **LEIA ISTO PRIMEIRO — ESTADO CANÔNICO**  
> Build atual: **1.0.4 Layout Review** · Godot **4.5.1** · Android **landscape-only** · `versionCode 13`.  
> O branch `main` é a fonte pública atual. Branches `release/*` e documentos antigos são históricos.  
> Se sua ferramenta só consegue ler o README do GitHub, este arquivo foi escrito para ser autocontido. Para ainda mais contexto em texto puro, leia `AI_CONTEXT.txt`.

## Estado atual

- Engine: Godot 4.5.1
- Plataforma: Android, somente horizontal
- Package: `com.entremargens.prototype`
- Viewport lógico: `960x540`
- Stretch: `canvas_items` + `expand`
- Renderer: GL Compatibility
- minSdk: 24
- target/compile SDK: 35
- ABIs: arm64-v8a + armeabi-v7a
- Aparelho físico principal para QA futuro: **POCO F7 — 2772x1280 landscape, 120 Hz**

A campanha atual tem **6 áreas, 16 encontros, 24 ondas e 2 desfechos**. O combate usa ataque corpo a corpo, esquiva, cura e três técnicas: **Cordão, Fratura e Contrapeso**. O chefe principal é o **Regulador**.

## Regra de ouro para outra IA

Antes de alterar o projeto:

1. leia este README e `AI_CONTEXT.txt`;
2. leia `docs/19_LAYOUT_RESPONSIVO_REVIEW_104.md` para HUD/touch;
3. leia `docs/17_POLIMENTO_GERAL_103.md`, `docs/16_LAYOUT_HORIZONTAL_102.md`, `docs/15_POLIMENTO_101.md` e `docs/14_POLIMENTO_100.md` quando a tarefa tocar apresentação/combate;
4. leia `docs/01_BIBLIA_DE_LORE.md` e `docs/09_REDESIGN_ACTION_RPG.md` antes de mudar cânone/conteúdo;
5. nunca editar `.gdc`; trabalhar nos `.gd` fonte;
6. em tarefas visuais, não alterar `combat.json`, dano, custo, cooldown, alcance, hitbox ou progressão;
7. manter 16 encontros / 24 ondas salvo pedido explícito de conteúdo novo.

## Arquitetura ativa

A campanha de ação vive principalmente em `godot/action/`:

```text
godot/action/
  main.gd          composição geral / menu / fluxo
  world.gd         mundo e integração espacial
  hud.gd           HUD e ÚNICA autoridade de layout responsivo
  touch.gd         input touch; recebe geometria pronta do HUD
  combat.gd        combate
  effects.gd       VFX manuais
  actor.gd         apresentação do jogador/NPCs
  machine.gd       máquinas/inimigos
  scenery.gd       cenário
  audio.gd         SFX, pitch, prioridades e ducking
  icons.gd         ícones do HUD
  campaign.gd      progressão + normalização de compatibilidade do snapshot público
  circuit.gd       puzzle de circuito
  save.gd          persistência da campanha
  preferences.gd   preferências + safe area Android
```

Dados principais:

```text
godot/data/action/campaign.json
godot/data/action/combat.json
```

### Nota de migração pública 0.5.1 → 1.0.4

O `main` nasceu do snapshot público 0.5.1. O `campaign.json` histórico é preservado, e `action/campaign.gd` aplica ao carregar **uma única normalização explícita**: `soleira_dena` recebe a técnica `contrapeso` e o parágrafo de aprendizado caso o campo ainda não exista. Isso reproduz o comportamento da build empacotada 1.0.4 sem alterar encontros, ondas, objetivos ou números de combate. A composição pública com essa normalização passou toda a suíte 1.0.4: 38/38, 230/230, 54 callbacks, 137/137 UI, 68/68 polimento e 87/87 apresentação.

### HUD/touch — arquitetura final 1.0.4

A primeira migração de anchors (`docs/18...`) foi **substituída** pela revisão 1.0.4 (`docs/19...`).

Na solução final:

- `hud.gd` é a única autoridade de layout;
- somente o HUD reage a `Viewport.size_changed`;
- `preferences.safe_rect()` combina margem do jogo com `DisplayServer.get_display_safe_area()` no Android;
- `touch.gd` NÃO lê resolução, NÃO consulta safe area e NÃO decide posição por aspect ratio;
- `touch.gd.apply_layout()` recebe centros/raios já resolvidos pelos `Control` nodes do HUD;
- `MarginContainer`, `VBoxContainer`, `HBoxContainer` e `GridContainer` são usados onde eliminam acoplamento;
- joystick fica bottom-left;
- ESQ/TÉCNICA/ATQ ficam bottom-right;
- Vigor/Foco + Curar ficam top-left;
- técnica ativa/DIÁRIO/MAPA/pausa ficam top-right;
- interação fica bottom-center;
- a Gameplay Core central não deve ser coberta por HUD persistente.

Não reintroduzir um segundo cálculo independente em `touch.gd`.

## Resolução / pixel art

`godot/project.godot` usa viewport base `960x540`, `canvas_items`, `expand`, filtro Nearest e renderer Compatibility. Valores como `ACTION_DIAMETER = 72` são **unidades lógicas**, não 72 pixels físicos do aparelho.

O produto é landscape-only. Retrato existe apenas como stress test arquitetural.

## Técnicas

- **Cordão:** anel de gelo ao redor do jogador; leitura circular clara.
- **Fratura:** fissura/linha de gelo saturada em direção ao alvo.
- **Contrapeso:** camada de gelo junto ao corpo; ao absorver golpe, quebra em fragmentos.

As três identidades visuais são distintas. Não reutilizar um mesmo efeito genérico para todas.

## Histórico relevante

- **0.5.1:** base anterior pública; QA/polimento inicial.
- **1.0:** campanha e apresentação ampliadas; correções de dedupe e UI.
- **1.0.1:** identidade visual de gelo para Cordão/Fratura/Contrapeso.
- **1.0.2:** jogo passa a ser landscape-only; menu principal e HUD horizontal.
- **1.0.3:** polimento geral visual/sonoro; sem rebalanceamento.
- **1.0.3 Layout Anchors:** primeira migração de anchors; histórica/superseded.
- **1.0.4 Layout Review:** arquitetura final de HUD/touch; build canônica.

## Testes da 1.0.4

Última suíte completa validada — incluindo a reconstrução exata do conteúdo público com seus assets:

```text
run_tests.gd          38/38
test_action.gd        230/230
test_action_draw.gd   54 callbacks
test_mobile_ui.gd     137/137
test_polish.gd        68/68
test_presentation.gd  87/87
```

O teste de UI inclui resize dinâmico:

```text
960x540 -> 1200x540 -> 540x960 -> 1170x540 -> 960x540
```

O passo retrato é só stress test; o APK continua landscape.

`combat.json` deve continuar byte-idêntico em tarefas puramente visuais. SHA-256 de referência:

```text
a875ff60d8827d6e37a550bda3a8dfdc0c2f3962f6b7d9af2ec0279af78603fe
```

## Build Android

Preset canônico:

```text
versionName: 1.0.4
versionCode: 13
package: com.entremargens.prototype
minSdk: 24
targetSdk: 35
orientation: landscape
```

A última APK validada usou assinatura v2/v3 e o mesmo certificado das builds anteriores. **Nunca commitar keystore/chave privada.** O diretório privado `development/` não faz parte do repositório público.

## Fontes e licenças

O jogo usa DejaVu Sans (`body.ttf`) e DejaVu Serif Bold (`title.ttf`). A auditoria confirmou os caracteres portugueses utilizados. Consulte `LICENCAS.md`, `godot/assets/CREDITOS.md` e `third_party/` antes de redistribuir assets.

## O que ainda precisa de validação humana

Ainda não considerar como concluído sem teste real:

- playtest completo no POCO F7;
- ergonomia dos controles por 20–30 minutos;
- safe area/notch real do aparelho;
- frame pacing a 60/120 Hz;
- aquecimento/bateria;
- tempo humano real da campanha.

## Próxima prioridade recomendada

1. Playtest físico no POCO F7 (`2772x1280`).
2. Transformar essa resolução em regressão permanente de UI.
3. Corrigir ergonomia apenas com evidência real do aparelho.
4. Depois continuar polimento de sprites, inimigos e cenário.

Não inventar automaticamente NG+, arena infinita, área 7, terceiro final ou “v2.0” apenas porque há espaço para expansão. Qualquer expansão de conteúdo deve ser uma decisão explícita do projeto.
