# Changelog

Todas as alterações notáveis deste projeto serão documentadas neste arquivo.

## [4.1] - 2026-11-17

### Corrigido & Otimizado
- **Fluidez Extrema na Alternância entre Lentes (0.5x Ultra-Wide, 1.0x Principal, 3.0x Telefoto):**
  - **Elevação do Piso de Clock da GPU Adreno 650 (490 MHz em Preview):** Fixação do `devfreq/min_freq` em 490 MHz e `idle_timer` em 100 ms durante o ciclo de câmera ativa. Elimina o micro-engasgo gráfico no crossfade de animação entre sensores provocado pelo repouso da GPU a 305 MHz.
  - **Sustentação de Núcleos Big & Prime em Preview de Câmera:** Frequência mínima elevada de 1.80 GHz para **2.25 GHz** nos núcleos Cortex-A77 Big (`policy4`) e de 2.17 GHz para **2.65 GHz** no núcleo Prime Cortex-A77 (`policy7`), com `schedtune.boost=35`. Acelera a curva de transição de zoom do UniHal (`samsung.android.control.zoomJumpTargetRatio`) e o cálculo de distorção de lente ArcSoft (`swuwdc.arcsoft.v1`).
  - **Priorização Total CFS (`cpu.shares: 8192`):** Concessão de peso máximo de agendamento CFS (8192 vs 1024 padrão) aos cgroups `camera-daemon` e `top-app`, isolando threads críticas de sincronização de streaming (`ZoomController` e `ZoomCurveHandlerThread`) de qualquer contenção com processos em segundo plano.
  - **Input Booster a 1.80 GHz no Toque:** Resposta ao toque inicial elevada para **1.80 GHz** nos núcleos Big (`200 1804800 1017 2 5` em `/sys/class/input_booster/touch/head`), conferindo resposta tátil imediata ao tocar nos botões circulares de troca de lente (0.5, 1, 3).
  - **Priorização Real-Time (`nice -20`) nos Daemons de Câmera:** Elevação dos processos `com.sec.android.app.camera`, `cameraserver` e `vendor.samsung.hardware.camera.provider@4.0-service_64` de `nice -15` para `nice -20`.
  - **Patamar Aprimorado em Gravação 4K 60fps:** Big a 2.42 GHz, Prime a 2.84 GHz e GPU a 587 MHz durante gravação ativa.
  - **Evidência em Benchmark de Runtime:** Em teste intensivo de comutação contínua entre as três lentes, a taxa de quadros fora da meta de 16.6ms despencou para apenas 1.69% (118 quadros renderizados com apenas 2 janks), 95º percentil em 10ms e 99º percentil em 16ms.

---

## [4.0] - 2026-11-17

### Corrigido & Otimizado
- **Resolução Definitiva dos Engasgos na Abertura da Câmera (Modo Foto e Vídeo):**
  - **Eliminação do OCR de Código QR em Tempo Real (`SaivQRCodeNode` / `QURAM_OCR`):** Desativação determinística de `qr_code_detection=0` nas preferências (`com.sec.android.app.camera_preferences.xml`), eliminando o processo de decodificação neural a cada quadro no preview que consumia de 50ms a 65ms por frame.
  - **Remoção de Conflito de Metadados CamX (`EISV3Enable` & Tag `0x80640001`):** Exclusão de `camxoverridesettings.txt` e limpeza das propriedades de persistência, sanando centenas de exceções de metadados por segundo e desafogando o daemon `vendor.samsung.hardware.camera.provider@4.0-service_64`.
  - **Sentinela 100% Orientado a Eventos (Futex do Kernel com `resetprop -w`):** Substituição do ciclo de polling por gatilhos nativos de futex do kernel nos eventos `service.camera.running` e `service.camera.rec.running`. O ramp de CPU (Little 1.46GHz, Big 1.80GHz, Prime 2.17GHz e `schedtune.boost=25`) agora ocorre em exatos 0 ms, antes mesmo da inflação da primeira view.
  - **Calibração de Memória e Marca d'Água do LMKD:** Redução de `min_free_kbytes` de 96 MB para 64 MB (`65536`), `watermark_scale_factor=50` e eliminação de `watermark_boost_factor=0`, erradicando os disparos espúrios do LMKD e matanças em lote de apps durante o cold start da câmera.
  - **Remoção de Limpeza de Cache no Gatilho de Câmera:** Remoção do `drop_caches=3` no momento exato de inicialização, preservando código DEX compilado e buffers de layout na pagecache do kernel.
  - **Priorização dos Daemons de Câmera e DSP:** Ajuste de prioridade em tempo real (`nice -15`) para `com.sec.android.app.camera`, `cameraserver`, codecs e drivers do sensor.

---

## [3.9] - 2026-11-17

### Adicionado
- **Armazenamento UFS 3.1 com agendador Deadline:** Migração das partições solid-state (`/sys/block/sd*`) de `cfq` para `deadline`, com `read_expire=100ms`, `write_expire=1000ms`, `rq_affinity=2` e fila de 256 requisições.
- **Input Booster a 1.46 GHz:** Elevação da resposta inicial ao toque (`/sys/class/input_booster/touch/head`) de 1.17 GHz para 1.46 GHz nos núcleos Big Cortex-A77.
- **Priorização em Tempo Real (Nice Clamping):**
  - Biometria óptica (`vendor.samsung.hardware.biometrics.fingerprint@3.0-service` e threads de captura) fixada em `nice -20`.
  - Subsistema de áudio (`audioserver`, `vendor.audio-hal`) e DSP Hexagon (`adsprpcd`) fixados em `nice -20`.
  - Câmera Qualcomm CamX e `cameraserver` priorizados em `nice -10`.
- **Manutenção Preventiva de Memória Contígua (CMA):** Verificação a cada 60s do pool `CmaFree`. Se inferior a 60 MB e câmera inativa, executa limpeza de pagecache limpo e compactação assíncrona em background.
- **Pilha TCP Otimizada:** Ativado `tcp_no_metrics_save=1`, `tcp_slow_start_after_idle=0`, `tcp_fastopen=3` e backlog de 10.000 buffers.
- **Standby & Sentinela Noturno:** Detecção de `mWakefulness=Asleep` com redução do ciclo de polling para 3s e agendamento de auto-trim silencioso (`sm fstrim`) a cada 24 horas.

### Modificado
- Suavização de dirty page writeback para 5s (`dirty_expire_centisecs: 500`) e 10s (`dirty_writeback_centisecs: 1000`).
- Expansão das margens de heap do ART Garbage Collector (`heapminfree=4m`, `heapmaxfree=16m`).
- Readahead do MicroSD (`mmcblk0`) calibrado para 1024 KB.

---

## [3.8] - 2026-11-17

### Corrigido
- **Eliminação do congelamento no 1º segundo em 4K 60fps (UHD 60):**
  - Proteção de ordens 4 a 10 no alocador do kernel via `min_free_kbytes: 98304` (96 MB) e `watermark_scale_factor: 100`, eliminando as pausas de compactação síncrona do CamX na alocação de buffers de 24.57 MB.
- **Fluidez na alternância de lentes:**
  - Forçado `adaptive_lens_mode=0` e `video_adaptive_lens_mode=0` em `camera_preferences.xml` para comutação direta sem hesitação de sensor.
- **Conflito de hardware OIS vs VDIS:**
  - Desativado o perspective grid do EIS via `EISV3Enable=FALSE` em `/data/vendor/camera/camxoverridesettings.txt`. O estabilizador óptico mecânico por hardware (**OIS magnético nos sensores principal e telefoto**) permanece 100% ativo.

---

## [3.0] - 2026-11-10

### Adicionado
- Escalonamento schedutil para resposta tátil de 1 ms (`up_rate_limit_us: 1000`) em `cpu0` e `cpu4`.
- Timer ocioso da Adreno 650 estendido para 80 ms (`idle_timer: 80ms`), sustentando os 120 Hz da tela sem micro-quedas.
- Alinhamento de renderização no SurfaceFlinger (`latch_unsignaled`).
- Política de retenção de processos em segundo plano no SLMK (`use_bg_keeping_policy=true` com suporte a 32 apps em cache).
- Bloqueio de rede no firewall local (`iptables`) para isolamento do dynamicSpot em loopback.
- Sentinela autônomo de retenção de backups do WhatsApp.
