# Verificação 0.2.0 — 3 de outubro de 2026

Godot 4.5.1 oficial, renderizador Compatibility. Dez GLBs exportados no Blender 5.2.2 do PC conectado. Materiais locais, sem serviço de rede no jogo.

- Importação das dez cenas GLB concluída.
- test_rules.gd: seis verificações de custo, recarga e defesa passaram.
- test_scene.gd: cena, chão físico, lança, onda, guarda, esquiva, projétil inimigo e movimento com ataque simultâneo passaram.
- test_polish.gd: escudo frontal reduz dano a 40%; retaguarda recebe dano completo; dez modelos carregados; pausa limpa movimento; derrota abre a opção de tentar novamente.
- Menu, combate e HUD capturados e revisados em 960×540, 1200×540 e 960×720. Capturas reais via OpenGL/Mesa por software. Não equivalem a medições de FPS no celular.
- APK ARM64, pacote com.entremargens.marefria, versão 0.2.0/código 2, Android mínimo API 24. Sem permissão de internet.
- Assinatura debug v2/v3 verificada. Mesmo certificado da 0.1.0: b588b6140c329efe5cea525481ab494acbf671a2e39cb470729d22dfa2fede39.
- Alinhamento de 16 KB verificado pelo zipalign.

Limitações: sem teste em aparelho Android físico, sem animações esqueléticas, sem checkpoints e sem campanha longa. O teste de encerramento de cena ainda emite aviso de instâncias remanescentes ao finalizar o processo de teste; não houve erro de script ou falha de asserção. A referência visual continua sendo uma meta, não uma captura deste jogo.
