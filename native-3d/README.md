# Entre Margens: Passo da Maré Fria

Protótipo nativo independente em Godot 4.5.1, primeira pessoa. Abra `project.godot` no editor e pressione F6/F5. Não depende de navegador, CDN ou servidor.

Novo guerreiro da Iqaluit fictícia do livro; braço moldado em gelo, lança com trajetória e colisão, soco com recarga, onda que causa dano e lentidão, guarda frontal temporária e esquiva com invulnerabilidade curta. Inimigos de artilharia disparam projéteis telegrafados. A fase segue uma passagem costeira até um abrigo. Relevo com colisão fora da passagem e feedback sonoro dos poderes. Cenário, guerreiro e técnicas são expansão proposta (N), não novos fatos canônicos do livro nem representação etnográfica de Iqaluit real.

Controles: WASD, mouse, clique para lança; Q soco, E onda, R guarda, Shift esquiva, Esc menu. No toque, esquerda move e direita olha; botões lançam poderes. Landscape recomendado.

## Android

APK 0.1.0 exportado para ARM64 (Android 7/API 24 ou superior), pacote `com.entremargens.marefria`, instalação separada da campanha antiga. Controles de toque com movimento e poderes simultâneos; modo paisagem. Exportação com templates oficiais Godot 4.5.1, assinatura debug e alinhamento de 16 KB verificados. Sem teste em aparelho físico.

Para repetir a exportação, configure Java 17, Android SDK e uma chave debug no editor, instale os templates oficiais 4.5.1 e execute `godot --headless --path native-3d --export-debug "Android APK" /caminho/Entre_Margens_Mare_Fria.apk`. Use a mesma chave para atualizar uma instalação existente.

Esta migração é uma base jogável, não entrega a qualidade gráfica da imagem de referência. Ainda faltam modelos esculpidos e animados, relevo e modelos com acabamento artístico, checkpoints, adversário final e avaliação em aparelho Android. As malhas atuais são provisórias. O projeto antigo em `godot/`, seus saves schema 4 e seu pacote Android permanecem preservados.

## Verificação

```
godot --headless --path native-3d --editor --quit
godot --headless --path native-3d --script scripts/test_rules.gd
godot --headless --path native-3d --script scripts/test_scene.gd
```

Texturas: Poly Haven, CC0. Consulte `LICENCAS.md`. Sem serviço externo em tempo de execução.
