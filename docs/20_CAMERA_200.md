# Entre Margens — candidata 2.0-camera.1

Base: release/1.0.4-canonical, f68ccac9526c0ef4bce4f30de365bbebe9b54da2. Android versionCode 14. Aguardando playtest físico no POCO F7.

Zoom real alterado de 1,45 para 1,00: 45% mais mundo por eixo, cerca de 2,10 vezes a área. Faixa do menu: 0,90–1,80. CAMERA_REVISION=1 migra a preferência antiga uma única vez e preserva escolhas posteriores, áudio, acessibilidade e campos não relacionados. O save da campanha não é regravado ao ajustar a apresentação.

Mantidos os limites das seis salas, o enquadramento temporário do chefe, a escala do HUD e os valores de combate. A prioridade de desenho do jogador durante combate já existia na 1.0.4 e ainda pode contribuir para a percepção de sobreposição: não declarar Y-sorting corrigido só por mudar zoom.

Esta etapa não inclui alterações de magia, controles, conteúdo ou balanceamento. Instalar como atualização e conferir Câmera 100% na primeira abertura. Avaliar antecipação de obstáculos, inimigos e comportamento nas bordas; só avançar nas magias após o retorno físico.

A reconstrução passou: domínio 38/38; ação 230/230; UI 137/137; polimento 68/68; apresentação 87/87; câmera 93/93; desenho 54 callbacks. Total: 653 verificações. Há avisos preexistentes de recursos em uso ao encerrar testes de UI/polimento. O APK tem assinatura v2/v3, alinhamento de 16 KiB e o mesmo certificado anterior. minSdk 24, targetSdk 35. SHA-256 do APK: 76f7ab466213bb454669fb8b9853a84143e454752ab0ed2d93a9435c61056462. Os testes automatizados não medem sensação de jogo nem desempenho no POCO F7.

Assets e módulos legados necessários para importar e rodar toda a suíte foram recuperados da cópia local do projeto, mantendo suas licenças e os scripts de ação da base 1.0.4. `combat.json` permanece byte-idêntico: a875ff60d8827d6e37a550bda3a8dfdc0c2f3962f6b7d9af2ec0279af78603fe.
