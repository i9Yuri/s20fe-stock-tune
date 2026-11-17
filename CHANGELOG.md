# Changelog

Todas as alterações notáveis deste projeto serão documentadas neste arquivo.

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
