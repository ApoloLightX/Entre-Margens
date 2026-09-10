# Arquitetura e expansão • protótipo 0.2

Android é agora o alvo principal. `scenes/touch_controls.gd` cuida exclusivamente da entrada multitoque; `core/game.gd` traduz essa direção e trata suspensão/retomada. `scenes/hud.gd` amplia menus e botões quando detecta Android. Exportação e assinatura estão em 07_ANDROID.md.

## Separação de responsabilidades

`core/catalog.gd` carrega e valida catálogos JSON. `core/state.gd` concentra somente estado serializável e valores iniciais. `core/game.gd` compõe serviços e traduz comandos de interface para operações de domínio. As regras não ficam no desenho da cena.

| Módulo | Responsabilidade |
|---|---|
| inventory | Capacidade, contagem e trocas sem cobrança parcial |
| farming | Plantio, umidade, calor, maturação e reparo |
| economy | Preços, estoque diário, venda, compra e receitas |
| relationships | Confiança e escolhas com bloqueio de repetição diária |
| quests | Elegibilidade e recompensa única por contrato |
| memory | Evidências, alteração de registro, proteção e decisões |
| clock | Tempo ativo, virada de dia e rótulo de calendário |
| foraging | Recursos, limite de pesca e achado único |
| save_service | Esquema, temporário, cópia anterior e recuperação |
| ambient_audio | Música provisória e variação de anomalia |
| scenes/world | Desenho, colisão simples, proximidade e rotina espacial |
| scenes/hud | Menus, diálogos, foco e apresentação de estado |

Os serviços de domínio são RefCounted, recebem dependências pelo construtor e podem ser instanciados sem cena. Mundo e interface leem o mesmo estado; não mantêm uma segunda carteira ou inventário. Catálogos usam identificadores estáveis; nomes visíveis não são chaves de salvamento.

## Adicionar conteúdo

Leia um registro existente como esquema mínimo. Adicione itens em `data/items.json`; uma cultura em `crops.json` precisa apontar para sementes e produto existentes. Receitas em `recipes.json` referenciam seus insumos e produto. A loja usa `shops.json`; quantidades e preços são dados. Um novo NPC exige registros compatíveis em `npcs.json` e `dialogues.json`, incluindo posições de rotina; não basta escrever um nome no mapa. `world.json` configura pontos de interesse e coleta. Execute os testes após alterar referências.

Os três contratos atuais são dados com condições pequenas interpretadas por `quests.gd`; adicionar um tipo novo de condição exige estender esse serviço. O diálogo atual oferece saudação e escolhas por pessoa, não um editor universal de grafos. Novas técnicas mágicas, relações complexas ou finais exigem regras e conteúdo próprios. Não prometer que qualquer sistema pode ser ampliado apenas por JSON.

## Memória e persistência

`evidence` é um dicionário por ID com valor, fonte e dia. `anchors` contém até três IDs protegidos. A virada para o dia 4 altera explicitamente o registro inicial sem âncora; dinheiro e colheitas não retrocedem. O circuito narrativo lê essas evidências, não uma variável de amizade disfarçada. Recuperação por segunda fonte evita bloquear quem não previu a anomalia.

O save tem `schema_version = 1`. A validação atual cobre estrutura principal, zonas e limites básicos; ainda não substitui validação exaustiva de cada campo aninhado. Migrações deverão ser funções explícitas entre versões com fixtures, preservando IDs e decisões anteriores. O arquivo é escrito temporariamente, validado, e então substitui o principal com cópia anterior. Não há cloud save nem sincronização.

## Preparação para cooperação futura

Separar domínio e apresentação facilita portar comandos para um anfitrião autoritativo, mas o protótipo ainda é single-player e modifica o estado local diretamente. Antes do multiplayer: formalizar comandos com ID, jogador e sequência; centralizar validação no host; tornar ticks reproduzíveis; decidir pausa compartilhada; separar memória pessoal e estado público; tratar reconexão e migração. Não foi implementado protocolo de rede, rollback, replicação ou segurança de servidor.

## Próxima divisão de cenas

Substituir desenho provisório por TileMapLayers, personagens animados e cenas de objetos interativos. Dividir telas do HUD em cenas independentes quando o conteúdo crescer. O desenho atual concentra apresentação em dois módulos; não colocar agricultura, economia ou memória neles. Adotar navegação e rotinas com resolução de conflitos antes de expandir para 24 NPCs. Perfilar no hardware mínimo escolhido antes de fechar orçamento de luzes e partículas.

## Build reproduzível

Godot 4.5.1 Standard. O preset `PC Pack` gera o pacote de conteúdo:

```bash
godot --headless --path godot --export-pack "PC Pack" EntreMargens.pck
```

Este pacote 0.1 foi combinado com os binários oficiais Windows x64 e Linux x86_64 da mesma versão e um inicializador local. Um lançamento deve usar os templates de exportação correspondentes, assinatura quando aplicável e QA nativo. Não empacotar a pasta `.godot` nem o romance original.
