---
name: entre-margens-combat
description: Manter combate e técnicas da campanha Entre Margens, preservando a separação entre regras mecânicas e feedback visual.
---

# Combate ativo

Ler `godot/action/combat.gd`, `godot/data/action/combat.json` e a Bíblia. `godot/systems/combat.gd` é legado. A campanha tem seis áreas, 16 encontros, 24 ondas e três técnicas: Cordão, Fratura, Contrapeso.

Em acabamento, preservar valores de combate, dados de campanha, câmera, toque, save schema 4 e IDs. Fratura mantém corredor forward>0 e <410, distância lateral <55; recoil 185 e dano/custo/cooldown dos dados. O ponto de impacto visual é capturado no alvo atingido mais próximo antes do recuo, sem nova consulta de colisão.

A ruptura da Fratura usa `source=fratura` e substitui a anterior. Suas camadas compartilham um efeito de 0,52 s (apenas VFX; spell_flash permanece 0,35 s). A apresentação elimina o arco genérico desse acerto via tone=fracture. Cordão e golpes físicos mantêm seus impactos. `tick_effects` limpa efeitos também durante hitstop; reset limpa tudo. Não criar marcas permanentes nem acumular uma cratera por alvo.

Preservar avisos antes do dano, vulnerabilidade de escudo, fases do Regulador e cancelamento de Contrapeso por esquiva. Rodar toda a suíte, incluindo `test_polish_210.gd`, e verificar desenho em movimento com um e três inimigos. Passar testes não aprova sensação nem desempenho no aparelho.
