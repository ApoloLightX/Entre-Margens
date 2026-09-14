# 22 — Diagnóstico e plano de acabamento 2.1

Estado: diagnóstico concluído; implementação, piloto renderizado, testes e build pendentes.
Data: 14/09/2026.
Base obrigatória: 2.0-polish.2, commit 31572a3cf73cdea37cc2e78ceab8601bdc899a80.
Este documento não representa uma build 2.1 pronta.

## Retorno físico do autor

O autor aprovou a build 2.0-polish.2 no POCO F7 quanto a câmera/zoom, ergonomia, esquiva, responsividade, leitura, diferenciação funcional e estabilidade. Preservar essas decisões. A aprovação da base não se estende às alterações ainda não implementadas da 2.1.

## Contexto consultado

Leitura das skills de pixel art, combate, visual polish e manutenção, seguida da Bíblia de Lore, na ordem solicitada. As três primeiras não constam dos caminhos esperados no ramo-base: foram consultadas as versões instaladas e a visual-polish anexada. Elas incluem descrições antigas; o código atual e as instruções explícitas do autor prevalecem. Antes da entrega, consolidar versões atualizadas nos caminhos do projeto.

Inspecionados action/combat.gd, effects.gd, spell_visuals.gd, world.gd, scenery.gd e terrain.gdshader. Inspeção visual direta dos atlas winter-house.png, winter-trees.png e dungeon.png efetuada antes da indisponibilidade do ambiente. campaign.json e arquivos de cenário conferidos novamente pelo GitHub.

## Fratura: causa observada e proposta

O cast atual aplica dano no corredor mecânico original e cria um efeito Fratura de 0,35 s. Cada acerto também cria um efeito genérico impact acima dos pés. spell_visuals.gd desenha a Fratura como linha com halo e fragmentos; effects.gd apresenta os impactos genéricos como arcos. O foreground tem z_index 4000: efeitos aparecem por cima do cenário e das máquinas. Isso ajuda a explicar a percepção de desenho flutuante; é uma hipótese visual apoiada na implementação, ainda sem comparação 2.1 renderizada.

Proposta:
- Preservar a seleção de alvos, instante de dano, alcance, custo, cooldown e recoil.
- Separar somente a apresentação da ruptura no chão dos efeitos acima dos corpos.
- Uma marca irregular principal por uso, no ponto de impacto escolhido entre os alvos realmente atingidos; capturar a posição antes do recuo. Sem alvo, usar ponto no corredor original, sem sugerir alcance ou dano adicionais.
- Região central quebrada assimétrica, cinco rachaduras com três segmentos afilados e seis estilhaços pequenos em trajetória curta.
- Sequência pressão/ruptura/expulsão/dissipação usando vida do efeito; sem alteração permanente de terreno, colisão ou navegação.
- Retirar apenas a linguagem circular dos impactos atribuídos à Fratura; não alterar os impactos de Cordão nem de ataques comuns.
- Manter ruptura abaixo de atores/avisos, com ordem de desenho explícita. Não mover todos os VFX para o chão.
- Não usar halo, Light2D ou partículas em Nodes independentes. Não usar aleatoriedade global do combate para variação cosmética.
- Cordão e Contrapeso mantêm seus visuais nesta rodada. Não há justificativa para dar a ambos a mesma cratera.

A marca principal única evita produzir uma cratera completa para cada inimigo no mesmo grupo. É preciso preservar também a leitura direcional da técnica, com fissuras discretas no corredor, sem recriar uma linha luminosa ou retícula. Quantidade, comprimento e tempo visual são parâmetros de piloto, não decisões aprovadas.

## Diagnóstico do cenário: implementação versus asset

| Elemento | Evidência atual | Origem predominante | Proposta limitada |
|---|---|---|---|
| Piso | Shader repete o recorte 16×16 em (80,0), ampliado em células de 48. Já existe variação de brilho por células de 96 e ruído fino na neve. | Implementação: aumentar apenas ruído não resolve a repetição estrutural. | Duas ou três variantes discretas de orientação/textura por célula, determinísticas; transição local suave. Evitar mudança global do shader. |
| Telhado | Recorte 64×64 esticado para toda a largura do prédio. A imagem-base tem uma grande massa quase uniforme de neve. | Asset e ampliação não uniforme. | Sombra do beiral, borda irregular e separação dos planos no piloto. Um telhado complementar dedicado é candidato real para acabamento posterior, sem trocar pack agora. |
| Fachada | Tiras centrais de 16 pixels repetidas para ampliar a parede; janelas manuais planas sobre a fachada. | Implementação + pouca variedade de material. | Reforçar profundidade do vão e contato do beiral, poucos sinais de desgaste. Não substituir dezenas de detalhes por código para mascarar o atlas. |
| Árvores | Atlas já possui neve irregular, galhos, tronco e variantes. scenery.gd usa sempre Rect2(0,0,96,144). | Principalmente implementação/reutilização. | Usar um segundo recorte existente validado, sem alterar posição ou tamanho de colisão; sombra adaptada à copa. Não redesenhar árvores completas. |
| Pedras | Recortes simples de snow.png ampliados. | Misto; qualidade final precisa de observação em cena. | Contato e pequena borda de gelo antes de considerar sprite complementar. |
| Colunas/estruturas | Recortes 16×32 ampliados para 60×120 e reaproveitados em vários tipos. | Limite de resolução e repetição do asset. | Sombra de contato e desgaste contido no piloto; estruturas únicas podem justificar sprite dedicado posteriormente. |
| Caixas/baús | Recortes pequenos ampliados; interativos também são desenhados em world.gd. | Misto. | Conferir contato, contorno e consistência entre scenery.gd/world.gd. Não alterar marcador ou área de interação. |
| Sombras | Elipse uniforme para todos os objetos, com escala Y 0,38 e alpha 0,25. | Implementação. | Base mais larga e leve + contato curto mais escuro, assimétricos conforme objeto. Desenho estático barato. |
| Local do chefe | Módulos repetidos do atlas e estrutura ampliada sem identidade própria de material. | Asset/composição. | Candidato a arte específica futura; fora dos dois pilotos desta rodada. |

Conclusão: o problema não é somente a simplicidade do pack. Árvores e chão têm ganho acessível por melhor implementação; o prédio principal e estruturas únicas têm um limite real no asset-base. Não trocar o pack nem espalhar hacks de acabamento pelo cenário inteiro.

## Pilotos propostos, ainda não aplicados

1. Vila, sala porto: prédio existente tile 0 em (450,410), árvore em (170,330) e mecanismo em (650,590). Trecho visual de referência aproximado Rect2(100,180,660,490). Não mover nem adicionar objetos.
2. Combate, sala vereda: casa existente tile 8 em (920,250), árvore em (1120,680), mecanismo em (680,440) e encontro já existente v2 em (930,450). Trecho aproximado Rect2(590,180,650,560). Não alterar encontro, quantidade de inimigos ou colisões.

Esses retângulos são recortes de apresentação, não novos limites de mapa. Delimitar acabamento local com transição para evitar costura abrupta; manter todos os demais trechos na base. Medir composição em câmera real antes de fixar as bordas finais.

Capturar antes/depois com câmera, zoom, resolução, posição e luz equivalentes. Avaliar piso, sombra, prédio, vegetação, interativos e leitura dos avisos inimigos. Não propagar para outras áreas sem avaliação do piloto.

## Validação pendente

- Inicialização, seis salas e transições; morte/restart.
- Fratura com um e três inimigos, ataques simultâneos, movimento e câmera de combate.
- Cordão, Contrapeso, esquiva e cancelamento; touch com dois dedos.
- Comparar hashes de combat.json, campaign.json e arquivos de câmera/controles com a base.
- Suíte completa existente e regressões específicas de ciclo de vida, sobreposição e limites do piloto.
- Comparação de custo do desenho com/sem acabamento nas mesmas condições. Contar Nodes/draw calls e registrar tempo medido, sem confundir captura no computador com desempenho no POCO F7.
- Exportar 2.1-polish.1 com nova versionCode, conferir certificado original e alinhamento.
- Entregar APK, ZIP completo, vídeo com áudio e comparação antes/depois.

Nenhum ganho de performance ou qualidade final foi medido nesta etapa. O ambiente de execução ficou indisponível em 14/09; a conexão GitHub permitiu concluir e salvar somente este diagnóstico. Nenhuma alteração de gameplay ou apresentação foi publicada como pronta. A última build instalável permanece 2.0-polish.2.
