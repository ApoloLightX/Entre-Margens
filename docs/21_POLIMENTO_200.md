# 21 — Polimento da série 2.0: magia e controles

Candidata **2.0-polish.2**, versionCode **15**, Godot 4.5.1. Base: `release/2.0-camera` (2.0-camera.1). Trabalho publicado em `release/2.0-polish`. Data: 13/09/2026.

## Escopo e autorização

O autor pediu para continuar as melhorias depois da câmera e entregar sempre vídeo e ZIP completo. Isso autoriza esta rodada de magia/ergonomia; não constitui aprovação física da câmera. Não houve conteúdo novo, rebalanceamento ou alteração do save schema 4. Foram consultadas as skills de combate, visual polish, manutenção e UI/UX.

## Substância visual das técnicas

`action/spell_visuals.gd` concentra a apresentação das três técnicas e é chamado por `action/effects.gd`. Um GradientTexture2D radial de 64×64 é reaproveitado pelo renderer. Não há criação de efeitos de combate no desenho: todas as camadas seguem a mesma vida e expiram com o efeito original.

- Cordão: halo periférico suave, facetas ascendentes de gelo claro e pequenos fragmentos. Centro aberto para ler o jogador e os avisos inimigos.
- Fratura: rastro azul com gradiente, fissura com núcleo claro e estilhaços sequenciais ao longo da direção original.
- Contrapeso: casca translúcida, placas prateadas e brilho de contato junto ao corpo. A esquiva continua cancelando a técnica e retirando suas camadas.

Os avisos inimigos, a prioridade do jogador e o espaçamento dos números de dano foram preservados. Movimento reduzido desativa deslocamento de partículas e pulsação; permanece o desaparecimento ligado ao tempo original. Não foi preciso migrar para GPUParticles2D: a quantidade limitada de elementos compartilha a instância já existente e evita outra fonte de estados e limpeza. Reavaliar partículas nativas apenas com evidência de ganho ou custo real no Android. O terreno unshaded não foi alterado.

Referência técnica: [GradientTexture2D, Godot 4.5](https://docs.godotengine.org/en/4.5/classes/class_gradienttexture2d.html).

## Ergonomia e HUD

`hud.gd` continua sendo a única autoridade de layout. Diâmetro visual dos botões de ação: 72 → 88 unidades lógicas. Joystick: 120 → 132. Espaçamento da grade de ações: 20; padding de hit: 6 por lado, portanto alvo circular de diâmetro 100 e intervalo livre de 8 entre alvos vizinhos. A margem lateral interna passou a 12 para conter inclusive a área invisível de toque dentro da safe area.

A barra superior reserva a largura do maior nome, Contrapeso, antes de aplicar sua âncora. Trocar técnica não empurra mais os botões para fora da borda. Feedback imediato ao toque e independência dos dedos foram preservados.

### Pixels físicos e dp

Com altura física 1280 e viewport lógico de altura 540, o fator é 2,37037. O botão visual de 88 equivale a 208,59 px e o alvo de 100 a 237,04 px. **Se** a densidade lógica Android for 4, isso representa 52,15 dp visuais e 59,26 dp de alvo. O botão anterior de 72 seria 42,67 dp visuais nesse cenário. Em 1280×720 com densidade lógica 2, o novo alvo equivale a 66,67 dp.

A densidade lógica real do POCO F7 ainda não foi medida. Estes cálculos são condicionais, não certificam 48 dp em todo aparelho/configuração. Densidades lógicas maiores ou áreas úteis menores podem exigir ajuste posterior. A proporção exata 2772/1280 foi testada, além de 960×540, 1170×540 e 1200×540.

Referências: [Android: alvo mínimo recomendado de 48 dp](https://developer.android.com/guide/topics/ui/accessibility/apps), [relação entre dp, pixels e densidade](https://developer.android.com/training/multiscreen/screendensities).

## Validação e prévia

**769 verificações aprovadas**, mais 54 callbacks de desenho nas seis áreas. Resultados completos em `tests-results/polish_200.json`. Testes novos cobrem limites da área real de toque, intervalos sem ação, dois dedos, nomes das três técnicas na barra superior e expiração/cancelamento de todas as camadas. A suíte existente verifica combo, esquiva, hitstop, telegraphs, fases do chefe, UI e câmera. O aviso legado de recursos ainda em uso ao encerrar test_polish e test_mobile_ui é registrado no relatório; não é um crash observado em gameplay.

`qa/preview_polish_200.gd` grava uma demonstração real no motor, em 1560×720 a 30 fps, com áudio. Os encontros com três inimigos e as entradas de toque são preparados para demonstrar Cordão, Fratura, Contrapeso e dois dedos. Vida/foco são restaurados entre demonstrações. O vídeo não é uma partida completa nem captura de aparelho físico e não comprova duração ou desempenho no POCO F7.

O arquivo de combate deve conservar SHA-256 `a875ff60d8827d6e37a550bda3a8dfdc0c2f3962f6b7d9af2ec0279af78603fe`. Pacote Android: `com.entremargens.prototype`, minSdk 24, targetSdk 35; mesmo certificado da candidata de câmera.

## Entrega e próximo playtest

Entregar APK, vídeo com áudio e ZIP contendo projeto-fonte completo, assets, documentação, testes e o instalador. Não incluir cache de importação ou chaves de assinatura. Manter o vídeo também dentro do ZIP.

No POCO F7: conferir campo de visão, alternância das três técnicas, leitura com três inimigos, toque simultâneo, conforto por uma sessão longa e recortes físicos da tela. Instalar como atualização sobre a build anterior. Não declarar a sensação resolvida antes do retorno do autor.
