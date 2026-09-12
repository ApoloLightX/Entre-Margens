# Entre Margens — Layout horizontal 1.0.2

## Escopo

Implementação da referência Figma de HUD largo (`2:12`) para jogo exclusivamente em orientação horizontal. O frame retrato `2:11` deixou de ser alvo de produto e de regressão.

## HUD

- Base lógica continua em 960×540 com `stretch/aspect=expand`.
- Margens da referência 1920×1080 foram mapeadas por metade: 28 px laterais/inferior e 32 px no topo.
- Vigor/Foco ficam no canto superior esquerdo; Curar imediatamente abaixo.
- Técnica ativa, Diário, Mapa e Pausa ficam no canto superior direito com gap fixo.
- Joystick: diâmetro visual máximo 120 px lógicos, preso ao canto inferior esquerdo.
- ATQ, TÉCNICA e ESQ: diâmetro 72 px lógicos, grade com gap 12 px no canto inferior direito.
- Interação deixou de usar texto flutuante: agora é um dock único, centralizado na parte inferior, com rótulo do alvo + botão de ação.

## Menu principal

A tela de título agora contém um card real de Menu Principal, responsivo em landscape, com:
- Continuar Travessia (quando existe save);
- Nova Travessia;
- Ajustes;
- Como Jogar.

Back em Ajustes/Créditos/Como Jogar retorna corretamente ao menu quando não há sessão ativa.

## Orientação e testes

`display/window/handheld/orientation=0` permanece explícito para landscape. A regressão mobile não usa mais viewport retrato e cobre:
- 960×540 (16:9);
- 1170×540 (19.5:9);
- 1200×540 (20:9).

Resultados de fechamento:
- domínio: 38/38;
- ação: 230/230;
- desenho: 54 callbacks;
- mobile UI: 57/57;
- polimento: 68/68;
- apresentação: 87/87.

A versão de exportação é 1.0.2 com versionCode 11 para evitar downgrade acidental sobre builds intermediárias anteriores.
