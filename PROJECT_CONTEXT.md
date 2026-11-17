# S20 FE Stock Tune — Documento Mestre de Arquitetura e Contexto Integral

Documento mestre de especificação técnica, governança e arquitetura para manutenção autônoma do módulo Magisk de calibração nativa do Samsung Galaxy S20 FE 5G (`r8q`).

---

## 1. Visão Geral e Objetivo do Sistema

O **S20 FE Stock Tune** é um módulo para gerenciadores de root (Magisk, KernelSU, APatch) projetado especificamente para o hardware do **Samsung Galaxy S20 FE 5G (Snapdragon 865 - SM-G780G / r8q, 8GB RAM)** rodando a ROM de fábrica **Stock One UI 5.1 (Android 13)**.

### Problema Central que Resolve
A Stock ROM original da Samsung impõe estrangulamentos severos de latência e alocação de recursos:
1. **Engasgo Inicial na Câmera 4K 60fps:** Ao iniciar gravações em UHD 60, o pipeline Qualcomm CamX exige múltiplos buffers contíguos de 24.57 MB. A fragmentação da RAM do kernel nas ordens 4 a 10 gerava pausas de compactação síncrona de 300ms a 700ms no primeiro segundo de vídeo.
2. **Hesitação na Troca de Lentes:** Modos adaptativos forçavam medições prévias de luz e distância antes de autorizar a lente telefoto física (3x óptica), gerando lentidão e crops digitais indesejados.
3. **Agendador de I/O em UFS 3.1:** Partições de memória flash operavam com `cfq`, agendador concebido para discos magnéticos rotacionais, introduzindo tempos de espera de fila desnecessários.
4. **Encerramento Agressivo de Apps (RAM 8GB):** O SLMK nativo fechava aplicativos úteis em cache para economizar memória, subutilizando os 8GB LPDDR5.
5. **Latência de Toque:** O Input Booster padrão subia a CPU para apenas 1.17 GHz no primeiro milissegundo de contato com a tela a 120Hz.

O objetivo do sistema é fornecer calibração cirúrgica de baixo nível (kernel, sysfs, EAS schedtune, Qualcomm CamX, Adreno GPU, UFS Deadline e prioridades em tempo real) via script de serviço com sentinela ativo em segundo plano de impacto nulo na bateria.

---

## 2. Mapa Estrutural do Repositório

```text
s20fe-stock-tune/
├── .agents/
│   └── rules/               # Regras de governança Spec-First e engenharia
├── META-INF/
│   └── com/
│       └── google/
│           └── android/
│               ├── update-binary     # Script de instalação flashable do módulo
│               └── updater-script    # Gatilho de compatibilidade Magisk (#MAGISK)
├── dist/                    # Saída compilada de pacotes .zip (ignorado no git)
├── .gitignore               # Regras de exclusão do Git
├── build.sh                 # Script automatizado de empacotamento do módulo .zip
├── CHANGELOG.md             # Histórico detalhado de alterações por versão
├── module.prop              # Metadados e identificação para o gerenciador Magisk
├── PROJECT_CONTEXT.md       # Este documento mestre de arquitetura
├── README.md                # Documentação técnica pública e guia de instalação
└── service.sh               # Daemon sentinela e orquestrador de calibração em boot
```

---

## 3. Ciclo de Vida e Fluxo de Execução do Sentinela

O script principal (`service.sh`) atua em duas etapas complementares:

### Etapa 1 — Calibração Pós-Boot (Executada uma única vez)
1. **Aguardar Boot Completo:** O script aguarda `sys.boot_completed=1` com timeout de segurança de 90 segundos.
2. **CPU & EAS Schedtune:** Ajusta `up_rate_limit_us=1000` (1ms) em `cpu0` (LITTLE) e `cpu4` (BIG); eleva `schedtune.prefer_idle=1` e `schedtune.boost=10` no cgroup `top-app`.
3. **GPU Adreno 650:** Altera `/sys/class/kgsl/kgsl-3d0/idle_timer` para 80ms, evitando queda brusca de clock de renderização durante rolagens a 120Hz.
4. **SurfaceFlinger:** Aplica offsets de renderização e habilita `latch_unsignaled` contra micro-jitter.
5. **Kernel VM & RAM Contígua:** Configura `min_free_kbytes=65536` (64MB), `watermark_scale_factor=50`, `watermark_boost_factor=0`, `dirty_expire=500` (5s), `dirty_writeback=1000` (10s) e ZRAM `page-cluster=0`.
6. **SLMK & Multitarefa:** Habilita política de retenção (`use_bg_keeping_policy=true`), `dha_cached_min=16`, `swap_free_low_percentage=15` e DHA para 32 apps.
7. **Armazenamento UFS 3.1 & MicroSD:** Altera `/sys/block/sd*/queue/scheduler` para `deadline` (`read_expire=100ms`, `write_expire=1000ms`, `rq_affinity=2`, `nr_requests=256`, `iostats=0`). MicroSD com readahead de 1024KB.
8. **Input Booster:** Parametriza `/sys/class/input_booster/touch/head` para 1.46GHz imediato nos núcleos Big.
9. **Rede TCP:** Define `tcp_no_metrics_save=1`, `tcp_slow_start_after_idle=0`, `tcp_fastopen=3` e backlog ampliado.
10. **Telemetria:** Desativa daemons `cnss_diag`, `ipacm-diag` e buffers de rastreamento `Perfetto`.
11. **Bateria e Doze:** Otimiza deep sleep e desativa varreduras Wi-Fi agressivas com tela apagada.
12. **Firewall Local:** Isola o aplicativo `dynamicSpot` permitindo tráfego somente em loopback (`127.0.0.1`).
13. **Câmera Stock & Preferências:** Remove `camxoverridesettings.txt` e limpa tags órfãs do CamX (`0x80640001`). Calibra `/data/data/com.sec.android.app.camera/shared_prefs/com.sec.android.app.camera_preferences.xml` desligando `qr_code_detection` (eliminando OCR em preview), `scene_optimizer`, e filtros de embelezamento.
14. **Priorização em Tempo Real:** Eleva para `nice -20` os daemons da biometria óptica e áudio DSP; eleva para `nice -15` os daemons de Câmera (`com.sec.android.app.camera`, `cameraserver` e `vendor.samsung.hardware.camera.provider@4.0-service_64`).
15. **WhatsApp:** Mantém apenas o banco de dados ativo e o último histórico diário, prevenindo acúmulo de múltiplos gigabytes residuais.

### Etapa 2 — Sentinela Nativamente Orientado a Eventos (Futex do Kernel)
* **Sentinela de Câmera (0ms de Latência):**
  * Aguarda mudanças na propriedade `service.camera.running` via futex do kernel (`resetprop -w`), eliminando loops de polling e consumo de CPU em repouso.
  * No exato microsegundo em que o app abre: eleva `top-app/schedtune.boost` para 25, sobe a frequência mínima de Little para 1.46 GHz, Big para 1.80 GHz e Prime para 2.17 GHz, e aplica `nice -15`.
  * Ao fechar a câmera: restaura frequências mínimas de repouso (300/710/845 MHz), boost normal e dispara compactação assíncrona.
* **Sentinela de Gravação 4K 60fps:**
  * Escuta `service.camera.rec.running` via futex. Ao gravar em 4K60, sobe Big para 2.02 GHz e Prime para 2.46 GHz sustentados.
* **Manutenção Periódica (a cada 60s):**
  * Audita `CmaFree`. Se < 60 MB e câmera inativa, executa desfragmentação preventiva.
  * Durante tela apagada (`mWakefulness=Asleep`): executa `sm fstrim` silenciosamente a cada 24 horas.

---

## 4. Restrições Críticas de Hardware, SO e Ambiente

* **Dispositivo Alvo Estrito:** Samsung Galaxy S20 FE 5G (`SM-G780G` / `r8q`).
* **SoC:** Qualcomm Snapdragon 865 (SM8250 - 1x Prime Kryo 585 @ 2.84GHz, 3x Gold Kryo 585 @ 2.42GHz, 4x Silver Kryo 585 @ 1.80GHz).
* **GPU:** Adreno 650.
* **Memória RAM:** 8GB LPDDR5.
* **Armazenamento:** 128GB UFS 3.1.
* **Sistema Operacional:** Stock One UI 5.1 baseada em Android 13 (`G780GXXSHEYJ1`, CSC `ZTO`). Kernel Linux 4.19.113.
* **Gerenciador de Root Suportado:** Magisk v24+ (testado em v28/v31), KernelSU v0.9+, APatch.
* **Proibição de Alteração de Partição de Sistema:** O módulo opera em espaço de usuário e nós do kernel (`sysfs`/`procfs`), preservando integridade das partições de leitura (`/system`, `/vendor`, `/product`).

---

## 5. Configurações Globais, Kernel e Sysfs

| Subsistema | Caminho / Parâmetro | Valor Calibrado | Justificativa |
| :--- | :--- | :--- | :--- |
| **CPU LITTLE** | `/sys/devices/system/cpu/cpufreq/policy0/schedutil/up_rate_limit_us` | `1000` (1ms) | Resposta tátil imediata |
| **CPU BIG** | `/sys/devices/system/cpu/cpufreq/policy4/schedutil/up_rate_limit_us` | `1000` (1ms) | Prevenção de micro-engasgos |
| **EAS Schedtune**| `/dev/stune/top-app/schedtune.prefer_idle` | `1` | Aloca threads de tela em núcleos ociosos |
| **EAS Schedtune**| `/dev/stune/top-app/schedtune.boost` | `10` (20 em gravação) | Priorização de threads da UI/CamX |
| **GPU Adreno** | `/sys/class/kgsl/kgsl-3d0/idle_timer` | `80` (80ms) | Sustenta 120Hz sem oscilação |
| **RAM VM** | `/proc/sys/vm/min_free_kbytes` | `98304` (96MB) | Reserva ordens 4-10 para buffers de 24.57MB |
| **RAM VM** | `/proc/sys/vm/watermark_scale_factor` | `100` | Ativa kswapd suavemente sem pausas de thread |
| **RAM VM** | `/proc/sys/vm/dirty_expire_centisecs` | `500` (5s) | Descarrega escritas sem congelamento |
| **RAM VM** | `/proc/sys/vm/dirty_writeback_centisecs` | `1000` (10s) | Intervalo de writeback contínuo |
| **UFS 3.1** | `/sys/block/sd*/queue/scheduler` | `deadline` | Elimina latência de espera do `cfq` rotacional |
| **UFS 3.1** | `/sys/block/sd*/queue/iosched/read_expire` | `100` (100ms) | Prioridade de leitura para apps e DBs |
| **Input Booster**| `/sys/class/input_booster/touch/head` | `150 1459200 1017 2 5` | Eleva clock para 1.46GHz no 1º ms do toque |
| **Biometria** | Daemon `vendor.samsung.hardware.biometrics.fingerprint@3.0-service` | `nice -20` | Desbloqueio óptico instantâneo |
| **Áudio DSP** | `audioserver`, `adsprpcd` | `nice -20` | Zero latência e sem engasgos no Viper4Android |
| **CamX Overrides**| `/data/vendor/camera/camxoverridesettings.txt` | `EISV3Enable=FALSE` | Remove VDIS instável; OIS mecânico 100% ativo |

---

## 6. Instruções Críticas para IAs que Modificarem Este Código

* **O QUE NUNCA FAZER:**
  1. **NUNCA desativar o OIS físico magnético:** O estabilizador mecânico das lentes principal e telefoto é essencial. Nunca desative o driver mecânico; a única coisa desativada é o VDIS de software que conflita com o CamX.
  2. **NUNCA reduzir `min_free_kbytes` abaixo de 64MB:** Menos de 64MB recria imediatamente a fragmentação de memória contígua e faz a câmera congelar no primeiro segundo de 4K 60fps.
  3. **NUNCA usar comandos `sleep` curtos (< 1s) em loops com tela apagada:** O sentinela em Deep Sleep DEVE dormir por pelo menos 3 segundos para garantir consumo de bateria rigorosamente zero.
  4. **NUNCA tentar alterar partições de sistema em modo de montagem read-write:** O dispositivo usa segurança EROFS/ext4 em system-as-root. Mantenha as modificações restritas a `/data/` e nós virtuais `/proc/` e `/sys/`.
  5. **NUNCA apagar dados do usuário em scripts de manutenção:** Arquivos de backup do WhatsApp devem preservar estritamente o banco ativo e o último histórico (`msgstore.db` + 1 `.crypt14`).
* **Comandos de Empacotamento:**
  - Para gerar o pacote flashable `.zip`:
    ```bash
    ./build.sh
    ```
  - Para testar e instalar diretamente no celular conectado via ADB:
    ```bash
    adb push dist/s20fe-stock-tune-v3.9.zip /data/local/tmp/mod.zip
    adb shell "su -c 'magisk --install-module /data/local/tmp/mod.zip; rm -f /data/local/tmp/mod.zip'"
    ```

---

## 7. Histórico de Versões e Decisões Críticas Recentes

* **v3.9 (2026-11-17):**
  - Implementado o agendador solid-state Deadline no UFS 3.1 com expiração de leitura de 100ms.
  - Calibrado Input Booster para 1.46 GHz no primeiro toque.
  - Priorização em tempo real (`nice -20`) para biometria óptica sobre a tela e áudio DSP Hexagon.
  - Sentinela de desfragmentação preventiva de CMA quando `CmaFree < 60MB`.
  - Agendador noturno de auto-trim silencioso via `sm fstrim` a cada 24 horas durante repouso.
* **v3.8 (2026-11-17):**
  - Resolução definitiva do congelamento em 4K 60fps através da proteção de ordens 4 a 10 no alocador de páginas do kernel (`min_free_kbytes: 96MB`).
  - Troca direta de sensores para eliminação da hesitação na lente telefoto 3x óptica.
  - Neutralização de conflito do VDIS de perspectiva com persistência de `EISV3Enable=FALSE` e preservação integral do OIS magnético por hardware.
