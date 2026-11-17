# S20 FE Stock Tune (Ultimate Edition)

[![Release](https://img.shields.io/github/v/release/i9Yuri/s20fe-stock-tune?color=blue&style=flat-square)](https://github.com/i9Yuri/s20fe-stock-tune/releases)
[![Platform](https://img.shields.io/badge/Device-Samsung%20Galaxy%20S20%20FE%205G%20(r8q)-informational?style=flat-square)](https://github.com/i9Yuri/s20fe-stock-tune)
[![ROM](https://img.shields.io/badge/ROM-Stock%20One%20UI%205.1%20(Android%2013)-orange?style=flat-square)](https://github.com/i9Yuri/s20fe-stock-tune)
[![Root](https://img.shields.io/badge/Root-Magisk%20%7C%20KernelSU%20%7C%20APatch-green?style=flat-square)](https://github.com/i9Yuri/s20fe-stock-tune)
[![License](https://img.shields.io/badge/License-MIT-lightgrey?style=flat-square)](LICENSE)

Módulo definitivo de calibração cirúrgica de baixo nível para o **Samsung Galaxy S20 FE 5G (Snapdragon 865 - SM-G780G / r8q, 8GB RAM)** rodando a ROM de fábrica **Stock One UI 5.1 (Android 13)**.

Elimina os gargalos crônicos da One UI original — como o congelamento no primeiro segundo de gravação em 4K 60fps, hesitação na alternância de lentes, atraso de I/O em UFS 3.1 com agendador rotacional e encerramento agressivo de aplicativos em segundo plano — sem substituir o kernel e sem quebrar os recursos proprietários da Samsung.

---

## 🎯 Destaques e Pilares Técnicos

### 1. Resolução Definitiva dos Engasgos na Câmera Stock (Modo Foto e Vídeo 4K60)
* **Sentinela 100% Orientado a Eventos (Futex Kernel):** O sentinela em segundo plano substitui completamente o polling de propriedades por escutas síncronas nativas nos eventos `service.camera.running` e `service.camera.rec.running` via futex do kernel. O ramp de frequências da CPU (Little 1.61GHz, Big 2.25GHz, Prime 2.65GHz, GPU 490MHz e `schedtune.boost=35`) é ativado em exatos **0 ms** de latência, antes mesmo de o aplicativo da câmera inflar sua interface.
* **Eliminação do OCR de Código QR em Tempo Real:** Nas versões de fábrica, o `SaivQRCodeNode` (`QURAM_OCR`) executava decodificação em segundo plano em cada quadro de visualização no modo foto, adicionando um atraso de 50ms a 65ms por frame na thread de renderização. O parâmetro `qr_code_detection: 0` nas preferências corta esse processamento desnecessário na raiz.
* **Integridade de Metadados CamX:** Eliminação do arquivo `camxoverridesettings.txt` e remoção da propriedade `persist.vendor.camera.EISV3Enable`. Essa medida erradica os erros recorrentes de sincronização de metadados (Tag `0x80640001`), desafogando o daemon `vendor.samsung.hardware.camera.provider@4.0-service_64`.
* **Calibração de Memória e Marca d'Água do LMKD:** Redução de `min_free_kbytes` para 64 MB (`65536`), `watermark_scale_factor: 50` e eliminação de `watermark_boost_factor: 0`. Isso impede que o LMKD dispare pânicos de alocação e encerramentos em massa de aplicativos em background durante a abertura da câmera.
* **Manutenção Preventiva de CMA:** O sentinela em segundo plano audita o pool `CmaFree` periodicamente. Se a memória contígua livre estiver abaixo de 60 MB e a câmera estiver fechada, ele executa desfragmentação e limpeza de pagecache assíncrona, garantindo prontidão para captura instantânea.

### 2. Fluidez Extrema na Alternância de Lentes e OIS por Hardware
* **Piso de Clock de GPU a 490 MHz em Preview:** Durante todo o ciclo da câmera aberta, a Adreno 650 tem piso elevado de 305 MHz para 490 MHz (`idle_timer: 100ms`). Isso assegura renderização gráfica contínua do crossfade e eliminação de frames descartados durante a troca de sensores.
* **Aceleração da Curva de Zoom e Correção de Distorção:** Sustentação de CPU Big a 2.25 GHz e Prime a 2.65 GHz, somados a `cpu.shares: 8192` (peso máximo de agendamento CFS) para `camera-daemon` e `top-app`. Acelera o cálculo dos passos intermediários da curva de zoom e a correção de distorção de lente ArcSoft (`swuwdc.arcsoft.v1`).
* **Transição Instantânea:** Desativação dos modos adaptativos (`adaptive_lens_mode=0` e `video_adaptive_lens_mode=0`), permitindo alternância direta entre Ultra-Wide (0.5x), Principal (1.0x) e Telefoto física (3.0x óptica).
* **OIS Magnético 100% Ativo:** O estabilizador óptico mecânico por hardware (**OIS físico magnético nos sensores principal e telefoto**) permanece operando em sua total plenitude, enquanto a estabilização de vídeo digital de software é desativada via preferências para máxima pureza e nitidez.

### 3. Armazenamento UFS 3.1 com Agendador Solid-State Deadline
* A Samsung entrega as partições UFS com agendador `cfq` (desenhado para discos rígidos mecânicos).
* O módulo aplica o agendador de estado sólido `deadline` com `read_expire=100ms`, `write_expire=1000ms`, `rq_affinity=2` e fila de 256 requisições, acelerando leituras de banco de dados (SQLite) e carregamento de apps.
* Readahead do cartão MicroSD (`mmcblk0`) calibrado para 1024 KB.

### 4. Input Booster & Resposta ao Toque
* Elevação do patamar de frequência do primeiro toque em `/sys/class/input_booster/touch/head` para **1.80 GHz** nos núcleos Cortex-A77 Big, cortando a latência de toque tanto na troca rápida de lentes quanto em rolagens de 120Hz.

### 5. Priorização em Tempo Real (Nice Clamping)
* **Biometria Óptica:** O daemon `vendor.samsung.hardware.biometrics.fingerprint@3.0-service` e suas threads de captura operam fixados em `nice -20`.
* **Áudio DSP Hexagon:** O `audioserver`, o `vendor.audio-hal` e o daemon `adsprpcd` do DSP Hexagon rodam em `nice -20`, garantindo reprodução sem estalos ou latência em equalizadores (ViPER4Android).
* **Câmera:** Daemons de captura (`com.sec.android.app.camera`, `vendor.samsung.hardware.camera.provider@4.0-service_64` e `cameraserver`) priorizados em tempo real em `nice -20`.

### 6. Multitarefa Expandida (SLMK 8GB) & Dirty Writeback
* Ativada a política nativa `use_bg_keeping_policy=true` com `dha_cached_min=16` e margem de swap em 15%, sustentando até 32 aplicativos em cache na memória RAM LPDDR5.
* Dirty page writeback suavizado (`dirty_expire=500` [5s] e `dirty_writeback=1000` [10s]), prevenindo picos de congelamento ao descarregar dados em disco.

### 7. Rede, Bateria e Standby Noturno
* `tcp_no_metrics_save=1` impede que conexões rápidas herdem limites de conexões Wi-Fi anteriores. TCP Fast Open ativado (`tcp_fastopen=3`).
* Detecção de Deep Sleep (`mWakefulness=Asleep`): consumo de CPU em repouso próximo de zero absoluto.
* Rotina de auto-trim silenciosa: `sm fstrim` disparado a cada 24 horas durante a tela desligada.

---

## 📦 Estrutura dos Arquivos

```text
s20fe-stock-tune/
├── META-INF/com/google/android/
│   ├── update-binary         # Instalador padrão flashable
│   └── updater-script        # Gatilho Magisk
├── build.sh                 # Script local para empacotar o .zip
├── module.prop              # Identificação do módulo
├── service.sh               # Sentinela adaptativo e orquestrador de boot
├── CHANGELOG.md             # Histórico detalhado de versões
├── PROJECT_CONTEXT.md       # Especificação técnica e restrições de arquitetura
└── README.md                # Este documento
```

---

## 🚀 Instalação

### Requisitos
* Samsung Galaxy S20 FE 5G (`SM-G780G` / `r8q`).
* Stock ROM One UI 5.1 (Android 13).
* Gerenciador de Root: **Magisk v24+**, **KernelSU** ou **APatch**.

### Método 1: Pelo Aplicativo Magisk (Recomendado)
1. Baixe o pacote flashable na página de [Releases](https://github.com/i9Yuri/s20fe-stock-tune/releases).
2. Abra o aplicativo do **Magisk** (ou KernelSU/APatch).
3. Vá na aba **Módulos** > **Instalar a partir do armazenamento**.
4. Selecione o arquivo `.zip` baixado e aguarde a instalação.
5. Reinicie o aparelho.

### Método 2: Via Linha de Comando (ADB Root)
```bash
adb push s20fe-stock-tune-v4.1.zip /data/local/tmp/mod.zip
adb shell "su -c 'magisk --install-module /data/local/tmp/mod.zip; rm -f /data/local/tmp/mod.zip'"
adb reboot
```

---

## 🔍 Como Verificar o Funcionamento em Runtime

Após o boot, o sentinela gera um log completo de execução e mantém telemetria contínua. Para inspecionar:

```bash
adb shell "su -c 'cat /data/adb/modules/s20fe_stock_tune/optimizer.log'"
```

Para verificar o processo em tempo real:
```bash
adb shell "ps -ef | grep service.sh | grep -v grep"
```

---

## 🛠️ Como Compilar a Partir do Código-Fonte

Clone o repositório e execute o script de empacotamento:

```bash
git clone https://github.com/i9Yuri/s20fe-stock-tune.git
cd s20fe-stock-tune
./build.sh
```

O arquivo final pronto para flash será gerado no diretório `dist/`.

---

## 📄 Licença

Distribuído sob a licença MIT. Consulte `LICENSE` para mais informações.
