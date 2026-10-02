# Entre Margens — Guerreiro de Iqaluit (3D)

Vertical slice experimental em **Godot 4.5.1**, criada para tirar a nova direção do navegador/HTML sem apagar a campanha 2D aprovada.

## Rodar

Abra `godot3d/project.godot` no Godot 4.5.1 e execute a cena principal.

Alvo principal: Android horizontal. Viewport lógico: 1280×720. Renderer: GL Compatibility.

## Identidade

O protagonista desta vertical slice é um **guerreiro de Iqaluit**. Não carrega arma convencional: o braço direito foi tomado por gelo cristalino e funciona como arma, foco visual e origem das técnicas.

### Combate

- **Garra de Geada** — ataque corpo a corpo do braço de gelo; recupera foco ao acertar.
- **Lança Glacial** — disparo concentrado de gelo em longa distância; desacelera o alvo.
- **Muralha** — ergue uma barreira temporária de gelo com colisão.
- **Pulso Boreal** — explosão em área que causa dano e congela inimigos próximos.
- **Passo Branco** — esquiva/dash curto.

Desktop: WASD + mouse, Q/E/R para técnicas, Shift para Passo e F para interagir.
Android: joystick esquerdo, câmera por arrasto no lado direito e botões dedicados.

## Fase

A fase não reutiliza a Calha Norte do protótipo HTML. A vertical slice se passa na **Margem de Iqaluit · Fenda Azul**, uma área aberta de neve, gelo, pequenos abrigos aquecidos e três rotas curtas.

O jogador precisa despertar três **Marcos de Vigília**:
1. Marco do Abrigo;
2. Marco da Fenda;
3. Marco do Vento.

As rotas se reencontram antes da Câmara do Vento, onde surge um Guardião. O desenho evita uma avenida reta: uma massa central de gelo corta a linha de visão e força a escolha esquerda/direita/elevação central.

## Status

Esta é uma expansão **N — elemento novo do spin-off**, criada por pedido explícito do autor em 01/10/2026. Não é apresentada como fato estabelecido no Livro I.

A campanha 2D em `godot/` permanece intacta para comparação e rollback.
