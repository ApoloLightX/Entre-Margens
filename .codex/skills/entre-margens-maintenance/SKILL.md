---
name: entre-margens-maintenance
description: Manter câmera, apresentação e exportação Android de Entre Margens; usar em correções de playtest e migração de preferências.
---

# Skill: manutenção de Entre Margens

Use esta skill ao alterar combate, HUD, arte, áudio, exportação Android ou lore.

1. Leia a skill específica da área antes de editar.
2. Faça mudanças pequenas e testáveis.
3. Preserve save schema 4, pacote com.entremargens.prototype e assinatura local em atualizações Android.
4. O código ativo está em godot/action/; godot/scenes/ e godot/systems/ são legado.
5. Consulte docs/01_BIBLIA_DE_LORE.md; não apresente invenção como cânone.
6. Atualize documentação e tests-results/ quando o comportamento mudar.
7. Não adicione texto, nomes, comentários ou assets que façam alusão a sistemas de geração automática.
8. Busque skills relevantes ao iniciar uma área nova e registre a decisão na revisão.
9. Use apenas assets com licença em LICENCAS.md.
10. Para Android, valide 960x540, 1200x540, 960x720, assinatura e alinhamento.

## Série 2.0

Ler docs/20_CAMERA_200.md e o retorno físico mais recente. A base desta candidata é release/1.0.4-canonical; não presumir que main está atualizado. O zoom real vem de user://presentation.cfg em action/preferences.gd; scripts de QA podem sobrescrevê-lo. CAMERA_REVISION=1 migra o zoom antigo uma única vez para 1,00; não incrementar em cada build nem apagar escolhas posteriores. HUD e main usam MIN_ZOOM/MAX_ZOOM da preferência.

Executar testes de migração com XDG_DATA_HOME isolado e a suíte completa. Conferir 2772x1280 além de 960x540, 1170x540 e 1200x540. Capturas não demonstram conforto ou desempenho. Esta rodada aguarda teste físico antes do trabalho nas magias; preservar conteúdo e valores de combate. Investigar ordenação do jogador se o cenário continuar parecendo errado.
