# Entre Margens — A Travessia Sem Nome

RPG de ação narrativo para Android, desenvolvido em Godot 4.5.1 no universo de A Voz Sob o Gelo.

## Estado atual

A campanha possui seis áreas, 16 encontros, 24 ondas, puzzles de circuitos, Cordão, Fratura, combate em tempo real, esquiva, Regulador em três fases, Diário de Âncoras, dois desfechos, salvamento com backup e controles de toque.

A pasta local contém o projeto Godot, documentação, testes, builds Android e os modelos de referência do Livro I. Consulte docs/01_BIBLIA_DE_LORE.md antes de alterar o cânone.

## Estrutura

- godot/action/: campanha ativa, combate, HUD, toque, áudio, efeitos e mundo.
- godot/data/action/: dados externos de salas, encontros, técnicas e diálogos.
- godot/assets/: sprites, tilesets, fontes, música e efeitos.
- docs/: lore, GDD, arquitetura, redesign e revisões.
- tests-results/: verificações automatizadas e exportações.
- book-reference/: arquivos do Livro I fornecidos para consulta.

## Executar

Abra godot/project.godot com Godot 4.5.1. Para Android, use OpenJDK 17, Android SDK e templates oficiais da mesma versão.

Não há conexão, anúncios ou compras obrigatórias. O conteúdo preserva os limites canônicos documentados e não usa assets, textos ou nomes de habilidades de jogos de referência.

## Manutenção

Mudanças importantes devem atualizar a documentação, os testes e a skill em .codex/skills/entre-margens-maintenance/SKILL.md. Skills externas devem ser avaliadas antes de entrar no runtime. Consulte LICENCAS.md antes de redistribuir qualquer asset.
