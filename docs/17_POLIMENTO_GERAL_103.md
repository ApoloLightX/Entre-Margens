# Entre Margens — polimento geral 1.0.3

A versão 1.0.3 parte da 1.0.2 horizontal e faz uma passada de apresentação geral sem alterar balanceamento, encontro, onda, área, progressão ou duração projetada. `data/action/combat.json` permanece intacto.

## Combate e legibilidade

- Acertos físicos e mágicos ganharam impacto próprio com arco direcional, núcleo e fragmentos; técnicas de gelo usam núcleo azulado e golpes físicos usam marfim/cobre.
- Bloqueios frontais agora mostram uma deflexão curta sobre o escudo, separada do dano flutuante.
- Entrada de inimigos usa um marcador curto de materialização mecânica, sem mudar quando ou onde eles surgem.
- Morte de mecanismos ganhou fragmentos de metal/cristal em vez de quadrados genéricos.
- Esquiva ganhou rastro com contorno escuro, preservando leitura na neve.
- Telegraphs hostis foram redesenhados para reduzir o emaranhado de linhas laranja: preenchimentos ficaram muito mais suaves, bordas ganharam contorno escuro e linhas longas passaram a usar trechos pontilhados e marcador de progresso. A geometria avisada continua exatamente a mesma da hitbox.

## Personagens e máquinas

- O protagonista ganhou squash/lean puramente visual em ataque, cast, dano, esquiva e Contrapeso, mantendo o ponto dos pés e colisão inalterados.
- Máquinas agora têm núcleo cromático por papel, pulso de preparação mais legível, hit-pop curto e barras de vida com moldura.

## Áudio

- Impactos fortes, dano recebido, quebra de aro do Regulador e Contrapeso fazem ducking breve da música. Isso abre espaço para Foley sem mudar volume configurado pelo jogador.
- O ducking se recupera suavemente e continua respeitando controles separados de música/efeitos e mute.

## HUD e toque

- Corrigida duplicação acidental do texto `FOCO` no desenho do HUD.
- Vigor baixo recebe apenas um acento lateral discreto; `Movimento reduzido` remove a pulsação.
- Toast ganhou uma linha de acento e o HUD do Regulador ganhou marcações de terços.
- O botão de TÉCNICA passa a refletir a identidade cromática de Cordão, Fratura e Contrapeso.
- Analógico mostra direção ativa com um traço curto, sem aumentar a área de toque.

## Escopo preservado

- orientação apenas horizontal;
- 6 áreas;
- 16 encontros;
- 24 ondas;
- ~30 min projetados;
- mesmos custos, danos, cooldowns, alcances, durações e hitboxes;
- save schema preservado;
- `versionName 1.0.3`, `versionCode 12`.

## Verificação

Rodar `test_polish.gd` e a suíte completa. Capturas QA devem incluir combate com três inimigos e o leque do Regulador para confirmar a redução de ruído dos telegraphs em 16:9.

### Resultado executado em Godot 4.5.1

Validação final: `tests/run_tests.gd` 38/38, `tests/test_action.gd` 230/230, `tests/test_action_draw.gd` 54 callbacks, `tests/test_mobile_ui.gd` 57/57, `tests/test_polish.gd` 68/68 e `tests/test_presentation.gd` 87/87. O SHA-256 de `godot/data/action/combat.json` permaneceu `a875ff60d8827d6e37a550bda3a8dfdc0c2f3962f6b7d9af2ec0279af78603fe`, idêntico à base 1.0.2/1.0 FINAL.

Capturas QA reais em Godot 4.5.1 confirmaram que o leque do Regulador fica muito menos carregado visualmente: todos os raios permanecem indicados, mas como trechos espaçados com marcador de progresso em vez de faixas laranja contínuas. O combate comum mantém contorno escuro sobre neve para preservar leitura.
