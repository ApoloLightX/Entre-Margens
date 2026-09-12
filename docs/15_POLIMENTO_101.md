# Entre Margens — polimento visual 1.0.1

A versão 1.0.1 parte da 1.0 FINAL e é uma revisão exclusivamente de apresentação das três técnicas. Custos, recargas, dano, alcance, duração, invulnerabilidade, restituição de Foco, hitboxes, encontros, ondas e progressão permanecem inalterados. O objetivo é corrigir a pouca diferenciação visual observada entre 0.5.1 e 1.0 sem reintroduzir excesso de efeitos em combate cheio.

## Identidade de gelo das técnicas

Cordão mantém sua interrupção em área e proteção breve, mas abandona a leitura de anel genérico. O perímetro mecânico continua no mesmo raio: uma linha escura fina preserva contraste sobre neve e, por cima dela, duas frentes claras fecham o círculo enquanto dez pequenos fragmentos convergem para a borda. A paleta é branco-azulada e translúcida, com núcleo quase branco.

Fratura mantém exatamente o mesmo impulso em linha e a mesma quebra de postura. Sua apresentação agora usa o tipo de efeito `fratura`: uma rachadura azul saturada avança em segmentos irregulares até o alcance já existente, com contorno azul-escuro, núcleo claro, ramificações laterais determinísticas e estilhaço curto na ponta. O desenho permanece uma única instância rastreada pela técnica; apresentações antigas `ring`/`beam` são descartadas quando necessário para evitar empilhamento residual.

Contrapeso deixa de usar uma forma radial. Durante a janela ativa, uma carapaça facetada pálida é desenhada em torno do corpo, atrás da silhueta do protagonista, com preenchimento muito discreto e borda escura para não sumir sobre a neve. Ao absorver o único golpe permitido, a carapaça desaparece e um efeito separado `contrapeso_break` lança dez fragmentos para fora do torso. Nenhum anel de expansão é usado pela técnica defensiva.

## Pose e som

O atlas existente já possuía duas células não utilizadas, 10 e 11, com leitura mais fechada do equipamento. Elas passam a compor a animação de apresentação `brace` do protagonista enquanto `guard_time` está ativo. A alteração é apenas de sprite apresentado; posição de pés, colisão, movimento e janela mecânica continuam comandados pelo estado de combate.

O áudio continua usando apenas gravações já licenciadas no projeto. Cordão conserva sinos de impacto, agora com registro levemente mais agudo; Fratura conserva vidro quebrando em registro mais grave; Contrapeso combina metal leve/sino no preparo. O bloqueio bem-sucedido usa vidro quebrando mais agudo, acompanhado por uma camada metálica baixa. Isso cria três assinaturas auditivas sem acrescentar arquivo externo ou nova dependência.

## Legibilidade

Os três efeitos usam contorno azul-escuro sob o gelo claro/saturado para manter leitura em cenários de neve. Cordão comunica área por perímetro circular, Fratura comunica direção por linha quebrada e Contrapeso comunica defesa por volume preso ao corpo; as três formas continuam distinguíveis sem depender apenas da cor.

O sistema manual de `action/effects.gd` foi preservado. Não foram introduzidos `GPUParticles2D`, luzes em tempo real ou emissão contínua. A prioridade visual do protagonista da 1.0 permanece acima da camada de efeitos durante combate, portanto a carapaça de Contrapeso não cobre a silhueta do jogador.

## Escopo preservado

- 6 áreas;
- 16 encontros;
- 24 ondas;
- aproximadamente 30 minutos projetados;
- save schema 4;
- pacote Android `com.entremargens.prototype`;
- nenhuma alteração em `data/action/combat.json`;
- nenhuma alteração de custo, cooldown, dano, alcance ou duração das técnicas.

## Versionamento

Android passa para `versionName 1.0.1` e `versionCode 9`. A identidade de assinatura de desenvolvimento é preservada para continuar a linha de atualização iniciada nas builds anteriores.

## Verificação

A suíte deve incluir o cenário explícito de três inimigos com Cordão, Fratura e Contrapeso em sequência, conferindo que cada técnica mantém uma única apresentação rastreada e um `kind` visual próprio. Também devem permanecer verdes os testes de deduplicação da Fratura, expiração durante hitstop, cancelamento de Contrapeso por esquiva, absorção de um único golpe, dano, foco, telegraphs, HUD Android, desenho e apresentação nas seis áreas.

### Resultado executado em Godot 4.5.1

Validação final concluída após a implementação: `tests/run_tests.gd` 38/38, `tests/test_action.gd` 230/230, `tests/test_action_draw.gd` 54 callbacks, `tests/test_mobile_ui.gd` 50/50, `tests/test_polish.gd` 68/68 e `tests/test_presentation.gd` 81/81. O SHA-256 de `data/action/combat.json` permaneceu `a875ff60d8827d6e37a550bda3a8dfdc0c2f3962f6b7d9af2ec0279af78603fe`, igual ao da base 1.0 FINAL.
