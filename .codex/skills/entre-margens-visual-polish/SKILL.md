---
name: entre-margens-visual-polish
description: Polir VFX, terreno e sombras de Entre Margens, especialmente a ruptura de gelo e os pilotos locais da série 2.1.
---

# Apresentação da série 2.1

Ler `docs/22_DIAGNOSTICO_210.md`, `docs/23_POLIMENTO_210.md` e os arquivos ativos antes de editar. A base 2.0-polish.2 teve câmera, ergonomia, esquiva e leitura aprovadas pelo autor no POCO F7.

`terrain.gdshader` continua unshaded. Não adicionar Light2D esperando afetar o piso. O acabamento usa o sistema manual de desenho, sem GPUParticles2D ou um Node por fragmento.

`world.gd` tem um passe permanente de `effects.gd` em z=-1, acima do terreno (-4000) e abaixo dos avisos do mundo e atores. Somente Fratura usa esse passe; foreground permanece em 4000. `ice_rupture.gd` contém o centro assimétrico, cinco fissuras afiladas e seis estilhaços com trajetória. Geometria é gerada uma vez no cast com RNG local. A vida do dicionário de combate governa tudo; não criar timers separados.

Preservar Cordão claro/periférico e Contrapeso preso ao corpo. Movimento reduzido suprime expansão e voo, mantendo fade. Não reintroduzir halo, círculo ou retícula na Fratura.

Cenário: `environment_pilot.gd` delimita dois exemplos; sombras em duas camadas, beiral/vãos e segundo recorte de árvore. Shader usa variação determinística local com transição de 64 unidades. PNGs e footprints permanecem iguais. Não esconder o limite de arte do telhado com um sistema crescente de remendos procedurais.

Comparar antes/depois na mesma câmera, resolução, luz e posição. `qa/capture_polish_210.gd` captura imagens; `qa/preview_polish_210.gd` grava com comandos simulados e áudio. `qa/benchmark_polish_210.gd` mede o renderer do computador, não Android. Não apresentar gravação como playtest físico. Entregar APK, vídeo e ZIP completo; aprovação visual final depende do autor.
