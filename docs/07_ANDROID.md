# Android APK • versão 0.2.1

**Correção 08/09:** criação em duas páginas, botões fixos e setas para rolagem. Veja 08_CORRECAO_ANDROID_021.md para o problema observado na gravação e os 12 novos testes.

**Android é a plataforma principal a partir desta revisão, conforme a orientação do usuário.** O APK 0.3 contém o redesign de RPG de ação; os pacotes de PC 0.1 são entregas anteriores e não são necessários para instalar o APK.

## Instalar e jogar

Baixe `Entre_Margens_Android_0.3.apk` no celular e abra o arquivo. Se o Android solicitar, permita que o aplicativo usado para abrir esse arquivo instale aplicativos. Depois da instalação, abra **Entre Margens**. O jogo usa a tela na horizontal e funciona offline.

Na vila, arraste o direcional circular à esquerda para caminhar. Toque em **Agir**, à direita, quando estiver perto de uma pessoa, leito, porta ou objeto. Diário, Bolsa e Pausa ficam na parte superior. Arraste os menus para rolar listas e diálogos. Na pesca, toque em Recolher ou use a opção sem timing. O botão Voltar do Android fecha menus; o menu Pausa permite salvar.

O protótipo tenta salvar automaticamente ao entrar em segundo plano. Isso não substitui salvar pelo menu antes de encerrar deliberadamente: um encerramento forçado do processo pode impedir qualquer aplicativo de executar código. Não há recuperação de dados após desinstalar o aplicativo nem sincronização online.

## Conteúdo e mudanças

A build 0.3 mantém os seis moradores, cultivo térmico, coleta, pesca, crafting, loja, contratos e primeiro arco do Diário. Acrescenta direcional e o redesign de ação com ataque, inimigos e técnicas mágicas. Também acrescenta multitoque, ação de proximidade por toque, botões maiores, menus ampliados, orientação horizontal, tratamento do botão Voltar e salvamento no evento de suspensão. O direcional é liberado ao abrir menus ou suspender, evitando movimento preso ao retornar. Teclado e controle continuam disponíveis no projeto, mas não são necessários para o APK.

Cânone, trama, elenco e divisão entre fatos e elementos novos não mudaram nesta adaptação. Pixel art final e romances extensos continuam no plano de produção.

## Verificação de base 0.2 e pacote atual

O pacote e a assinatura abaixo foram novamente verificados em 0.2.1. Os 38 testes seguintes são o histórico da versão 0.2; os 12 novos testes de interface estão no relatório 0.2.1.

- Pacote: `com.entremargens.prototype`, versão interna do manifesto `0.2.1`, código 3; conteúdo de combate da revisão 0.3.
- Manifesto: SDK mínimo 24 (Android 7.0), alvo 35; inclui ARM de 32 e 64 bits. Esse mínimo de instalação não é uma garantia de desempenho em todo aparelho antigo.
- APK exportado e assinado: assinatura v2 e v3 verificada com `apksigner`.
- Alinhamento de pacote verificado com `zipalign -c -P 16 4`.
- 38 testes de regras e entrada, zero falhas. Incluem captura do dedo, zona morta, limite de velocidade, segundo dedo e liberação do direcional.
- Cenas e menus ampliados instanciados em teste headless com `--touch`.
- O manifesto final não solicita permissões Android de rede, microfone, câmera ou armazenamento compartilhado.

**Não foi instalado em aparelho físico nem executado em emulador Android nesta sessão.** A assinatura válida e o manifesto não comprovam legibilidade, desempenho, áudio ou comportamento de todos os gestos em um dispositivo real. A inspeção gráfica permanece pendente. A build continua protótipo, com arte e áudio provisórios. O aviso de recursos ainda vivos no encerramento headless também permanece registrado no relatório 0.1.

## Reproduzir o APK

Use Godot 4.5.1 Standard, OpenJDK 17, Android SDK e os templates de exportação 4.5.1. Configure os caminhos Java e Android nas preferências do editor. O preset **Android APK** usa exportação de template, sem Gradle customizado. Ative a importação ETC2/ASTC, já configurada neste projeto.

O preset usa a chave de desenvolvimento incluída em `development/android-debug.keystore`, alias `androiddebugkey`, senha padrão de desenvolvimento `android`. Essa identidade existe para permitir atualizações do protótipo; não é uma credencial de distribuição comercial. Uma publicação deve configurar sua própria assinatura de produção e seu processo de atualização.

```bash
godot --headless --path godot --export-debug "Android APK" Entre_Margens_Android_0.3.apk
```

O preset entregue usa os templates oficiais instalados normalmente. Na sessão de geração, o mesmo `android_debug.apk` foi extraído do arquivo oficial de templates 4.5.1 e informado como template externo. O arquivo de 1,35 GB completo de templates não é redistribuído no projeto-fonte.

Referência técnica: [exportação Android — documentação oficial Godot 4.5](https://docs.godotengine.org/en/4.5/tutorials/export/exporting_for_android.html).
