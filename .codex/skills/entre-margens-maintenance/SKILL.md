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

Executar testes de migração com XDG_DATA_HOME isolado e a suíte completa. Conferir 2772x1280 além de 960x540, 1170x540 e 1200x540. Capturas não demonstram conforto ou desempenho. O autor autorizou continuar as magias após a câmera; a aprovação física da câmera continua pendente. Preservar conteúdo e valores de combate. Investigar ordenação do jogador se o cenário continuar parecendo errado.


## Polimento 2.0 e entregas

Ler docs/21_POLIMENTO_200.md. A candidata atual é 2.0-polish.2, versionCode 15, release/2.0-polish. spell_visuals.gd só desenha camadas, usa gradiente radial em cache e segue life/max dos efeitos de combat.gd; nunca criar outra instância de combate por camada. Preservar cores e centro livre. Contrapeso deve retirar todas as camadas ao cancelar com esquiva. Respeitar movimento reduzido.

HUD: ação 88, padding de hit 6, gap visual 20, joystick 132 e margem lateral 12. Testar o alvo inteiro, não somente o desenho. Reservar no HUD a largura do maior nome de técnica antes de ancorar a barra superior. Não mover cálculos de layout para touch.gd. dp depende de densidade lógica Android; não confundir resolução ou PPI físico com densidade medida.

Após cada entrega importante, atualizar esta skill ou criar uma específica quando necessário, consultar skills relevantes e enviar SEMPRE vídeo de gameplay com áudio e ZIP completo além do APK. Usar qa/preview_polish_200.gd como referência de gravação no motor; identificar comandos simulados e nunca apresentar esse vídeo como playtest físico. Incluir fonte, assets, docs, testes e APK no ZIP; excluir caches, keystores e intermediários AVI. Confirmar assinatura e alinhamento do APK. Publicar fonte/skill no ramo de trabalho e informar que o teste físico está pendente até o autor avaliar.


## Estado 2.1 — precedência sobre o histórico acima

A base 2.0-polish.2 foi aprovada fisicamente pelo autor no POCO F7. Não reabrir a aprovação da câmera ou ergonomia dessa base. A candidata 2.1-polish.1 (versionCode 16) ainda requer playtest próprio. Ler docs/23_POLIMENTO_210.md; preservar piloto local e regras de combate. As quatro skills agora existem nos caminhos do repositório. Usar qa/preview_polish_210.gd para a entrega desta versão.
