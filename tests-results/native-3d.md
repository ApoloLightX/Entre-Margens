# Passo da Maré Fria

Migração isolada em native-3d, Godot 4.5.1. Preserva projeto legado, save schema 4 e pacote Android.

Escopo validado por scripts: custo limítrofe, recarga, poder desconhecido, redução de dano, instanciação da cena com sete adversários, projétil sem duplicação durante recarga, guarda, onda com lentidão, soco sem repetição durante recarga, esquiva com custo e recarga e contato físico com chão. A execução headless não mede qualidade visual, FPS mobile, assinatura nem alinhamento Android. APK Android exportado na revisão seguinte, conforme verificação abaixo.

Direção da revisão: skill entre-margens-combat e frontend; novas técnicas e fase registradas como expansão N. Meta visual da referência ainda não atingida. Não se apresenta o protótipo como versão final.

Capturas reais em OpenGL Compatibility/Mesa llvmpipe nas janelas 960x540, 1200x540, 960x720 e 1280x720. O tamanho virtual do canvas segue a configuração do projeto. Inspeção visual de HUD e botões; esses testes em desktop não substituem validação de toque no aparelho. Artilharia verificada por instanciação e atualização de projétil hostil durante o teste de cena.

## Exportação Android 0.1.0

- Godot 4.5.1, templates oficiais, Java 17, Android Build Tools 35.0.0.
- ARM64, pacote com.entremargens.marefria, API mínima 24 e alvo 35.
- Assinaturas APK v2 e v3 válidas; zipalign com páginas de 16 KB passou.
- Sem permissão de internet no manifesto.
- Teste de dois dedos: movimento permanece ativo ao acionar soco; soltura libera movimento. Teste de cena passou.
- Capturas do HUD nas resoluções do relatório anterior; APK não executado em aparelho físico.
- SHA-256 APK: 6882c255659d9e7cf648c2906852e1dda5c7a6ba505e8d627a72b23c436ee2c1
- Tamanho: 34138280 bytes.
