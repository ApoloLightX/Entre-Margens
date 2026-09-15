# 23 — Fratura no chão e dois pilotos de cenário

Candidata **2.1-polish.1**, Android versionCode **16**, Godot **4.5.1**. Base 2.0-polish.2, commit `31572a3`. Ramo `work/2.1-polish`. Implementação em 14–15/09/2026. APK exportado e verificado; aprovação física da 2.1 pendente.

## Base e escopo

O autor aprovou fisicamente a câmera, ergonomia, esquiva, responsividade, leitura de combate e estabilidade da 2.0-polish.2 no POCO F7. Esta revisão preserva esses arquivos. Não há alteração de mapa, conteúdo, lore, progressão, encontros, inimigos ou valores de combate. O diagnóstico anterior está em `22_DIAGNOSTICO_210.md`.

As quatro skills foram consultadas na ordem pedida, seguidas da Bíblia; versões antigas instaladas foram confrontadas com o runtime. Agora as quatro orientações estão nos caminhos `.codex/skills/entre-margens-*/SKILL.md` do projeto e distinguem a base aprovada da candidata atual.

## Fratura

`combat.gd` captura o ponto dos pés do alvo atingido mais próximo antes do recuo. Sem alvo, a marca fica a 205 unidades, dentro do corredor original. A seleção e o dano continuam instantâneos, com as mesmas condições de alcance, lateralidade e recuo. O tom de apresentação `fracture` retira somente o arco genérico por acerto dessa técnica; textos de dano e flash do inimigo continuam funcionando.

`ice_rupture.gd` desenha uma região central irregular, cinco placas de gelo partido, cinco fissuras assimétricas de três segmentos afilados e seis fragmentos triangulares em trajetória desacelerada com elevação/queda. A geometria é criada uma vez por uso com RNG local; o desenho não altera o RNG do combate. O caminho até o impacto tem pequenos trechos quebrados discretos, sem halo ou feixe brilhante.

A abertura precede os fragmentos. A duração **visual** passa de 0,35 para 0,52 segundo para permitir leitura após o recuo; não altera a duração mecânica nem o `spell_flash` de 0,35. Fragmentos desaparecem antes da marca; a marca nunca se torna terreno, colisão ou navegação. Recast substitui a anterior, inclusive com três alvos, e a limpeza segue `tick_effects` durante hitstop e `reset` nas transições.

`world.gd` reutiliza `effects.gd` em um passe permanente de chão (z=-1), acima do terreno (z=-4000) e abaixo dos atores/avisos. Foreground continua em 4000 para os demais efeitos. Há **um Node adicional por mundo**, não um por impacto ou fragmento. Movimento reduzido remove expansão e trajetória e preserva fade. Cordão e Contrapeso mantêm suas formas e não recebem crateras.

## Diagnóstico → proposta → piloto → avaliação

O diagnóstico foi salvo antes da implementação. A proposta foi apresentada e aplicada somente nos recortes de `environment_pilot.gd`:

| Piloto | Recorte lógico | Acabamento |
|---|---|---|
| Porto / vila | (100,180), 660×490 | Segundo recorte de copa, sombra de contato, plano de neve, beiral, vãos e peitoris, desgaste contido no prédio existente |
| Vereda / combate | (590,180), 650×560 | Mesma direção visual nos objetos existentes, piso com variação local e sombras em duas camadas |

O shader continua unshaded. Reaproveita o recorte do piso com três orientações determinísticas e mistura sutil; a transição local tem 64 unidades. Não há modificação dos PNGs, posições, quantidades ou colisões. O restante das áreas continua com a apresentação-base.

**Ganhos observados em captura:** copas menos repetidas, contato mais definido, janelas com profundidade e separação entre parede e telhado. O piso fica discretamente menos uniforme. **Limitações:** o telhado continua uma grande massa simples; as colunas pequenas ampliadas também têm limite de detalhe. Um sprite complementar do prédio principal ou das estruturas únicas seria mais adequado para uma futura melhoria substancial. Não houve troca de pack.

**Custo de produção:** baixo para os dois pilotos, pois reutilizam recortes e poucos elementos de desenho; não foi realizada arte original nova. Propagar exigiria revisar cada footprint/atlas. **Risco:** diferenças entre trechos polidos e antigos, sombras duplicadas já pintadas no atlas, e detalhes pequenos em excesso. Por isso a direção não foi propagada globalmente. O piloto fica disponível para a avaliação do autor.

## Testes e limites da evidência

A suíte completa passou após a Fratura e após os pilotos. A execução final inclui:

| Suíte | Resultado |
|---|---:|
| Domínio legado | 38/38 |
| Campanha / ação | 230/230 |
| UI mobile | 137/137 |
| Câmera | 93/93 |
| Polimento anterior | 68/68 |
| Apresentação | 87/87 |
| Polimento 2.0 | 116/116 |
| Polimento 2.1 | 572/572 |
| Desenho | 54 callbacks nas seis áreas |

Total: **1.341 verificações**, além dos callbacks. Muitos checks 2.1 verificam individualmente que os props permanecem restritos aos dois pilotos; a contagem não representa 572 situações de gameplay distintas. Relatórios e logs completos em `tests-results/polish-210/`.

Cobertura: inicialização, seis salas/transições, Fratura com 0/1/3 alvos, limites do corredor, custo/dano/recuo, deduplicação, expiração no hitstop, RNG, movimento reduzido, morte/restart, Cordão, Contrapeso/cancelamento, esquiva, colisão, HUD, câmera, redimensionamento e dois dedos. Arquivos mecânicos e de câmera/touch listados em `preserved-files.json` são byte-idênticos à base. Logs de parte das suítes antigas continuam trazendo avisos de recursos em uso no encerramento; nenhuma falha de script ou teste foi observada.

Capturas reais do renderer foram verificadas em 2772×1280. A gravação usa 1560×720 a 30 fps, áudio e controles simulados. Vida/foco e encontros são preparados para a demonstração; não é partida completa nem gravação de aparelho. Os primeiros trechos comparam antes/depois na mesma câmera e posição. O restante mostra um alvo, três alvos, movimento, ataque, esquiva e as três técnicas.

## Custo do piloto

`qa/benchmark_polish_210.gd` alterna antes/depois duas vezes por sala, 60 frames medidos após aquecimento, 1560×720, llvmpipe/Mesa por software. O JSON bruto fica em `tests-results/polish-210/benchmark.json`. O Node de chão existe nas duas opções; o piloto de cenário não acrescenta Nodes. Na primeira medição, Porto passou de 94 para 113 draw calls e Vereda de 78 para 101; os tempos variaram entre execuções. Esses números são evidência do custo de desenho, **não certificação de desempenho Android, 60/120 Hz ou bateria**.

## Reprodução e entrega

- Importar `godot/project.godot` com Godot 4.5.1.
- Suíte: `python qa/run_suite.py --godot /caminho/para/godot`.
- Capturas: executar `qa/capture_polish_210.gd` com renderer gráfico, resolução 2772×1280.
- Vídeo: executar `qa/preview_polish_210.gd` com `--write-movie` e `--fixed-fps 30`; converter AVI para H.264/AAC.
- Exportar pelo preset Android APK usando templates oficiais 4.5.1 e a chave privada original em `development/` (excluída do Git e do ZIP).

Entregar APK, vídeo com áudio, comparação antes/depois e ZIP com fonte, assets, docs, testes e os mesmos entregáveis. Teste físico solicitado: Fratura contra um/grupo de inimigos, legibilidade da cratera após recuo, qualidade dos dois pilotos, frame pacing e regressões de toque/câmera. A aprovação da 2.0 não equivale à aprovação desta candidata.

Referência de implementação: [CanvasItem no Godot 4.5 — ordem de desenho e primitivas](https://docs.godotengine.org/en/4.5/classes/class_canvasitem.html).


## APK conferido — 15/09/2026

Exportação concluída com template oficial Godot 4.5.1 íntegro (CRC32 db7f8371). Pacote com.entremargens.prototype, versionCode 16, minSdk 24, targetSdk 35, ARMv7/ARM64. Assinaturas v2/v3 e alinhamento de 16 KiB conferidos. O certificado SHA-256 é `4e6086b767e78d9944a73a4e0e56a5b6c0f2f0cbd3c685af974e0039a28df18b`. O APK inclui os módulos novos e passou a verificação CRC do ZIP. SHA-256 do instalador: `652b727525fb35bc4642d8bef77fe1036a68ba632b020d7342a224b49401d4f5`. A chave privada original fica fora da distribuição. Não houve instalação em dispositivo nesta sessão.
