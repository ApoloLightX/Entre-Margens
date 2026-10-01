# 24 — Vertical slice 3D: Guerreiro de Iqaluit

Data: 01/10/2026  
Ramo: `work/3.0-iqaluit-icewarrior`  
Engine: Godot 4.5.1 / GL Compatibility

## Motivo da mudança

O experimento HTML/Three.js chegou a uma apresentação visual inconsistente: cenário acumulado em camadas, leitura excessivamente linear, módulos escuros e dependência de correções locais. O vídeo físico enviado pelo autor em 01/10 mostrou que a leitura de escala e frio funcionava, mas o cenário ainda parecia protótipo e o armamento destoava da identidade do spin-off.

Por decisão explícita do autor, a próxima direção:
- sai do HTML como produto principal;
- retorna ao GitHub;
- usa Godot;
- substitui a arma por um braço de gelo;
- muda integralmente as técnicas;
- transforma o protagonista em guerreiro de Iqaluit;
- troca a fase.

## Escopo desta vertical slice

Não converte a campanha 2D existente nem apaga a candidata 2.1. O diretório `godot3d/` é independente para permitir avaliação A/B.

### Protagonista

Novo elemento do spin-off (N): guerreiro de Iqaluit com braço direito cristalizado.

A apresentação evita atribuir ao povo Inuit práticas, símbolos ou poderes tradicionais inventados. O braço de gelo pertence à ficção de Entre Margens, não é descrito como tradição cultural real.

### Kit

| Ação | Função |
|---|---|
| Garra de Geada | golpe próximo, 24 de dano, recupera foco |
| Lança Glacial | 48 de dano, longo alcance, slow |
| Muralha | barreira física temporária |
| Pulso Boreal | área, dano + congelamento |
| Passo Branco | dash curto |

Os valores são parâmetros da vertical slice e não substituem `godot/data/action/combat.json`.

## Nova fase — Margem de Iqaluit · Fenda Azul

O desenho abandona a passarela industrial reta.

Estrutura:
- entrada em campo de neve;
- massa de gelo central bloqueando a visão do objetivo final;
- rota esquerda pelos abrigos;
- rota direita pela Fenda Azul;
- rota central pelo Marco do Vento;
- convergência na Câmara do Vento;
- Guardião final.

Três Marcos de Vigília dão um objetivo legível sem transformar o mapa em corredor. Cada marco exige limpar inimigos próximos antes da interação.

A linguagem visual prioriza:
- gelo orgânico;
- rocha escura;
- neve;
- pequenos abrigos de luz quente;
- aurora;
- baixa densidade industrial;
- contraste frio/quente.

## Arquitetura

`godot3d/` usa:
- `scripts/main.gd`: ambiente e composição;
- `scripts/player.gd`: CharacterBody3D, câmera, braço de gelo, poderes;
- `scripts/enemy.gd`: inimigos e Guardião;
- `scripts/level.gd`: fase e progressão;
- `scripts/hud.gd`: HUD/touch;
- `shaders/ice.gdshader`: material cristalino;
- `shaders/snow.gdshader`: neve;
- `shaders/aurora.gdshader`: céu.

O projeto evita runtime online. Não há dependência de HTML, Three.js ou CDN.

## Validação

O ramo possui workflow `.github/workflows/validate-godot3d.yml` para importar e executar um smoke test headless no Godot 4.5.1.

Ainda é obrigatório validar no POCO F7:
- orientação horizontal;
- toque simultâneo;
- conforto da câmera;
- escala do braço;
- desempenho;
- aquecimento;
- leitura dos três caminhos;
- combate contra o Guardião.

A campanha 2D e seu save schema 4 não foram modificados.
