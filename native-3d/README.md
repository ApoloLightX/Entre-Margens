# Entre Margens: Passo da Maré Fria

Protótipo nativo independente em Godot 4.5.1, primeira pessoa. Abra `project.godot` no editor e pressione F6/F5. Não depende de navegador, CDN ou servidor.

Novo guerreiro da Iqaluit fictícia do livro; braço moldado em gelo, lança com trajetória e colisão, soco com recarga, onda que causa dano e lentidão, guarda frontal temporária. A fase segue uma passagem costeira até um abrigo. Relevo com colisão fora da passagem e feedback sonoro dos poderes. Cenário, guerreiro e técnicas são expansão proposta (N), não novos fatos canônicos do livro nem representação etnográfica de Iqaluit real.

Controles: WASD, mouse, clique para lança; Q soco, E onda, R guarda, Esc menu. No toque, esquerda move e direita olha; botões lançam poderes. Landscape recomendado.

Esta migração é uma base jogável, não entrega a qualidade gráfica da imagem de referência. Ainda faltam modelos esculpidos e animados, relevo e modelos com acabamento artístico, esquiva, checkpoints, adversário final e avaliação em aparelho Android. As malhas atuais são provisórias. O projeto antigo em `godot/`, seus saves schema 4 e seu pacote Android permanecem preservados.

## Verificação

```
godot --headless --path native-3d --editor --quit
godot --headless --path native-3d --script scripts/test_rules.gd
godot --headless --path native-3d --script scripts/test_scene.gd
```

Texturas: Poly Haven, CC0. Consulte `LICENCAS.md`. Sem serviço externo em tempo de execução.
