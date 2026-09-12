# Entre Margens — versão 1.0

A versão 1.0 parte diretamente da build Android 0.5.1 e preserva as seis áreas, 16 encontros, 24 ondas, os dois desfechos, o esquema de save 4 e o pacote `com.entremargens.prototype`. O trabalho desta revisão foi dividido em duas etapas: primeiro legibilidade em combate sob alta densidade; depois uma técnica nova sem aumentar a duração estrutural da campanha.

## Legibilidade de combate

A Fratura agora mantém uma única apresentação ativa por uso. Efeitos antigos da própria técnica são substituídos no recast, e efeitos transitórios continuam consumindo sua duração durante hitstop. Com isso, anéis e linhas não ficam congelados nem se acumulam entre impactos próximos.

O bloqueio frontal do guarda deixou de escrever `ESCUDO` sobre cada inimigo. O feedback passou a ser um ícone compacto, ligado ao identificador visual do inimigo e distribuído em pequenas faixas quando vários alvos estão próximos. Números de dano usam faixas equivalentes e recebem contorno escuro em quatro direções para manter contraste sobre neve, pedra, personagens e efeitos.

Durante combate ativo, o protagonista recebe prioridade de desenho ligeiramente acima da camada de efeitos. Fora do combate, a ordenação normal pela altura dos pés permanece. A mudança não altera hitbox, dano, recarga, hitstop, invulnerabilidade ou movimentação já validados na 0.5.1.

## Técnica nova — Contrapeso

Contrapeso é uma terceira técnica original da campanha. Em vez de causar dano ou ampliar uma área, ela firma o equipamento por uma janela curta e absorve um único impacto se o ataque chegar durante esse intervalo. A postura segura a posição do jogador, pode ser cancelada imediatamente pela esquiva e se encerra ao bloquear um golpe ou ao expirar.

Configuração da versão 1.0:

- custo: 24 de Foco;
- recarga: 4,0 s;
- janela ativa: 0,58 s;
- absorve um único impacto;
- bloqueio bem-sucedido devolve 14 de Foco e concede 0,28 s de proteção após o contato;
- expirar sem contato não concede proteção residual.

A técnica usa um ícone próprio e uma apresentação angular curta ao redor do protagonista. O som reutiliza impactos metálicos já licenciados no projeto. Nenhum asset externo novo foi necessário.

Contrapeso é aprendido em uma interação já existente na Soleira Desenterrada, junto à instrução de manutenção deixada por Dena. Não foi criado encontro, onda, sala ou objetivo adicional. Assim, o orçamento continua em 16 encontros, 24 ondas e aproximadamente 30 minutos projetados para uma primeira partida; essa duração ainda depende de playtest humano para confirmação.

## Interface, save e compatibilidade

A seleção de técnica percorre Cordão, Fratura e Contrapeso apenas entre técnicas aprendidas. A ajuda explica a função da nova postura. O save continua no esquema 4; saves da 0.5.1 permanecem válidos porque Cordão e Fratura mantêm os mesmos identificadores, e Contrapeso apenas amplia a lista aceita.

A exportação Android usa `versionName 1.0`, `versionCode 8`, o mesmo pacote `com.entremargens.prototype` e a mesma identidade de assinatura de desenvolvimento da 0.5.1. Isso mantém a linha de atualização do protótipo.

## Verificação

A validação foi executada com Godot 4.5.1 e incluiu o caso bloqueante de três ou mais inimigos próximos, múltiplos bloqueios e números de dano simultâneos.

- 38/38 verificações da base;
- 230/230 verificações da campanha de ação;
- 54 callbacks de desenho executados;
- 50/50 verificações de UI Android;
- 64/64 verificações de polimento;
- 81/81 verificações de apresentação.

Os testes cobrem, entre outros pontos, deduplicação da Fratura, expiração de efeitos durante hitstop, distribuição de status e dano, prioridade visual do protagonista, cancelamento de Contrapeso pela esquiva, consumo de um único golpe, expiração sem proteção residual, ciclo das três técnicas e round-trip do save.

O encerramento headless ainda registra avisos de recursos em uso em parte das suítes, sem falha de teste. Não houve instalação em aparelho Android físico nem execução em emulador nesta revisão; conforto de toque, desempenho, bateria, áudio em alto-falante de celular e duração humana completa continuam como validações de dispositivo.
