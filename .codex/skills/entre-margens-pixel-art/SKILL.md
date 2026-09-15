---
name: entre-margens-pixel-art
description: Trabalhar nos sprites, atlas e acabamento de cenário da campanha Entre Margens em Godot 4.5.1 para Android.
---

# Arte da campanha ativa

A campanha usa sprites reais em `godot/assets/sprites/`; `godot/action/` é o runtime ativo. Não usar instruções antigas que descrevem tudo como placeholder. Ler `docs/01_BIBLIA_DE_LORE.md`, `docs/22_DIAGNOSTICO_210.md` e `docs/23_POLIMENTO_210.md`.

Preservar viewport 960×540, canvas_items/expand, Nearest e Compatibility, incluindo câmera e toque aprovados na 2.0-polish.2. Não forçar stretch integer nesta base: alteraria o enquadramento aprovado.

Inspecionar o atlas antes de decidir que falta arte. `winter-trees.png` possui duas copas de 96×144; a segunda está em x=96. O telhado de `winter-house.png` é simples e esticado: detalhes de código têm ganho limitado. Uma arte complementar merece avaliação futura, sem trocar pack automaticamente.

A 2.1 aplica acabamento somente em retângulos de Porto e Vereda, definidos em `environment_pilot.gd`. `environment_polish=false` permite a comparação da apresentação no QA; não é preferência do jogador. Não mover props nem mudar colisões para acomodar o visual. Não propagar o piloto antes de avaliação.

Registrar licença e origem de qualquer asset novo em LICENCAS.md. Os assets atuais foram mantidos, com recortes e sobreposições de apresentação; não atribuir autoria exclusiva aos sprites de terceiros.
