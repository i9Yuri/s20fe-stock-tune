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

### 1. Resolução Definitiva do Congelamento em 4K 60fps (UHD 60)
* **Diagnóstico da Causa Raiz:** O pipeline Qualcomm CamX aloca sequencialmente múltiplos buffers contíguos de 24.57 MB ao gravar em 4K 60fps. Na ROM original, a fragmentação da RAM física zerava as ordens 4 a 10 do alocador do kernel, forçando o sistema a rodar compactação de memória síncrona com pausas de 300ms a 700ms no primeiro segundo.
* **Calibração Implementada:** Parâmetros `min_free_kbytes: 98304` (96 MB) e `watermark_scale_factor: 100` mantêm as ordens 4-10 blindadas para alocação direta.
* **Manutenção Preventiva de CMA:** O sentinela em segundo plano audita o pool `CmaFree` a cada 60s. Se a memória contígua livre estiver abaixo de 60 MB e a câmera estiver fechada, ele executa desfragmentação e limpeza de pagecache assíncrona, garantindo que o hardware esteja pronto para filmagem instantânea.

### 2. Fluidez na Alternância de Lentes e OIS por Hardware
* **Transição Instantânea:** Desativação dos modos adaptativos (`adaptive_lens_mode=0` e `video_adaptive_lens_mode=0`), permitindo alternância direta e imediata entre Ultra-Wide (0.5x), Principal (1.0x) e Telefoto física (3.0x óptica).
* **OIS Magnético Preservado:** Persistido `EISV3Enable=FALSE` em `/data/vendor/camera/camxoverridesettings.txt`. O estabilizador óptico mecânico por hardware (**OIS físico magnético nos sensores principal e telefoto**) permanece **100% ativo**, enquanto o VDIS de software instável é neutralizado.

### 3. Armazenamento UFS 3.1 com Agendador Solid-State Deadline
* A Samsung entrega as partições UFS com agendador `cfq` (desenhado para discos rígidos mecânicos).
* O módulo aplica o agendador de estado sólido `deadline` com `read_expire=100ms`, `write_expire=1000ms`, `rq_affinity=2` e fila de 256 requisições, acelerando leituras de banco de dados (SQLite) e carregamento de apps.
* Readahead do cartão MicroSD (`mmcblk0`) elevado para 1024 KB.

### 4. Input Booster & Resposta ao Toque
* Elevação do patamar de frequência do primeiro toque em `/sys/class/input_booster/touch/head` de 1.17 GHz para **1.46 GHz** nos núcleos Cortex-A77 Big, cortando a latência de toque em rolagens de 120Hz.

### 5. Priorização em Tempo Real (Nice Clamping)
* **Biometria Óptica:** O daemon `vendor.samsung.hardware.biometrics.fingerprint@3.0-service` e suas threads de captura operam fixados em `nice -20`.
* **Áudio DSP Hexagon:** O `audioserver`, o `vendor.audio-hal` e o daemon `adsprpcd` do DSP Hexagon rodam em `nice -20`, garantindo reprodução sem estalos ou latência em equalizadores (ViPER4Android).
* **Câmera:** Daemons de captura e processamento fotográfico priorizados em `nice -10`.

### 6. Multitarefa Expandida (SLMK 8GB) & Dirty Writeback
* Ativada a política nativa `use_bg_keeping_policy=true` com `dha_cached_min=16` e margem de swap em 15%, sustentando até 32 aplicativos em cache na memória RAM LPDDR5.
* Dirty page writeback suavizado (`dirty_expire=500` [5s] e `dirty_writeback=1000` [10s]), prevenindo picos de congelamento ao descarregar dados em disco.

### 7. Rede, Bateria e Standby Noturno
* `tcp_no_metrics_save=1` impede que conexões rápidas herdem limites de conexões Wi-Fi anteriores. TCP Fast Open ativado (`tcp_fastopen=3`).
* Detecção de Deep Sleep (`mWakefulness=Asleep`): transição do sentinela para sleep de 3s (consumo de CPU = 0.0%).
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
adb push s20fe-stock-tune-v3.9.zip /data/local/tmp/mod.zip
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
