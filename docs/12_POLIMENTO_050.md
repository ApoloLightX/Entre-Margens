# Revisão de apresentação 0.5.0

A revisão atende ao pedido de aumentar a leitura no Android e substituir a apresentação genérica da campanha. A história, as seis áreas, os identificadores de objetivos, os dois finais e o esquema de save 4 foram mantidos.

## Skills aplicadas

- entre-margens-pixel-art: sprites e atlas de artistas, filtro Nearest, coordenadas de pés como referência de profundidade, organização de assets e licença explícita.
- entre-margens-combat: apresentação separada da simulação, animação de preparação/contato, feedback de acerto, regras existentes de foco, esquiva, escudo e chefe preservadas.
- ui-ux-pro-max: controles para toque, áreas seguras, texto legível, rodapés fixos, navegação de Voltar e preferência de movimento reduzido.

Não foram instaladas bibliotecas de combate ou plugins externos no runtime. Os padrões foram aplicados aos módulos existentes em Godot 4.5.1.

## Apresentação

Câmera com padrão 1,45×, intervalo 1,15–1,80× e um pequeno deslocamento para mostrar o caminho à frente. O chefe usa 1,20× no máximo e enquadramento entre os dois atores para acomodar sua silhueta. A interface usa referência lógica 960×540, stretch expand e margens adaptadas à área segura Android. Nearest e snap de transformações preservam bordas definidas; zoom fracionário pode produzir larguras de pixel diferentes. Escala inteira de toda a janela não foi imposta, para aproveitar telas largas de celular.

Os atores usam AnimatedSprite2D, quatro quadros de caminhada, quatro de espada, quatro de conjuração e oito direções. Idle tem dois quadros. Esquiva usa quadros existentes com deslocamento e inclinação, sem alegar uma sequência exclusiva desenhada para ela. A cena ordena atores e objetos pela altura dos pés. Árvores, casas e máquinas têm módulos próprios; mapas e colisões continuam definidos pelos dados originais.

O ataque começa com preparação de 80 ms; o contato é resolvido durante a animação. Um acerto causa faíscas, som e pausa de 27 ms, ou 45 ms no terceiro golpe. A esquiva pode cancelar o contato pendente. A câmera reage suavemente a impactos, e isso pode ser desativado. A neve decorativa também para com Movimento reduzido.

O fundo usa pedra texturizada e neve com bordas discretas; ambientes têm paleta fria com cobre e luz âmbar. Os três atlas gerados da versão 0.4 e os WAVs sintetizados não são mais distribuídos na pasta ativa. A nova arte vem de packs de artistas: os créditos e adaptações estão em LICENCAS.md. Ela ainda não equivale a uma produção artística exclusiva com a densidade de um RPG comercial.

## Som

Duas faixas em Ogg Vorbis, crossfade entre exploração e confronto do chefe, redução de volume ao abrir menus e alteração gradual e pequena de afinação durante a anomalia. SFX de metal, cristal, tecido, passos por piso, interface e preparação inimiga. Variações alternadas evitam repetição idêntica; a reprodução simultânea tem limite de 12 vozes.

Volumes de música e efeitos são independentes. A música pausa ao suspender o aplicativo. Não foram usadas vozes sintetizadas nem músicas extraídas do jogo de referência. Na captura de teste o pico medido ficou abaixo de 0 dBFS; isso não substitui ouvir e ajustar a mixagem em alto-falantes de celular.

## Interface e salvamento

Menu inicial próprio; botões de ataque, magia e esquiva com ícones e anéis de recarga. Analógico e ações mantêm donos de toque independentes. Texto de diálogo maior, opção de texto grande, corpos roláveis e botões de fechar fixos. Preferências ficam em user://presentation.cfg; não alteram decisões nem âncoras.

Voltar no título permanece no título. Voltar em ajustes retorna ao menu de origem. Voltar no diálogo do chefe executa a continuação, incluindo seu início, sem permitir pular o gatilho. O botão Continuar é habilitado depois do primeiro salvamento na mesma sessão.

## Verificação e limites

218 verificações da campanha e 78 de apresentação passaram. A segunda suíte cobre três proporções (960×540, 1200×540 e 960×720), rodapés, texto grande, navegação, persistência de preferências e reprodução dos arquivos de combate. O teste de campanha cobre ataque com contato atrasado, foco, escudo, esquiva, projéteis, reforços, salvamento/backup, âncoras e os dois finais.

A revisão gráfica e a captura de prévia foram feitas no Godot 4.5.1 em Linux, com renderer Compatibility/Mesa. O vídeo de 20 segundos mostra cenas de teste com entrada roteirizada e áudio capturado pelo motor; não representa um playtest completo nem uma gravação do APK no celular. Relatórios da exportação e verificações do APK ficam em tests-results.

A build mantém com.entremargens.prototype e o certificado de desenvolvimento anterior, agora com versionCode 5 e versionName 0.5.0. A instalação em Android físico, conforto em diferentes recortes de tela, desempenho, consumo de bateria e a duração humana da campanha continuam sem validação. A meta de 25–35 minutos não foi medida nesta revisão.
