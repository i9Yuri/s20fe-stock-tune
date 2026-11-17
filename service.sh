#!/system/bin/sh
MODDIR=${0%/*}
LOGFILE="$MODDIR/optimizer.log"

log() {
    echo "[$(date "+%Y-%m-%d %H:%M:%S")] $1" >> "$LOGFILE"
}

log "=== Iniciando S20 FE One UI 5.1 Ultimate Stock Optimizer v4.1 ==="

# Aguarda boot completo e desbloqueio inicial
until [ "$(getprop sys.boot_completed)" = "1" ]; do
    sleep 3
done
sleep 5

log "Sistema estabilizado. Aplicando calibrações de elite v4.1..."

# 1. CPU Governors, EAS Schedtune & Agendador (Snapdragon 865)
for cpu in 0 1 2 3 4 5 6 7; do
    echo "schedutil" > /sys/devices/system/cpu/cpu$cpu/cpufreq/scaling_governor 2>/dev/null
    echo 1000 > /sys/devices/system/cpu/cpu$cpu/cpufreq/schedutil/up_rate_limit_us 2>/dev/null
    echo 10000 > /sys/devices/system/cpu/cpu$cpu/cpufreq/schedutil/down_rate_limit_us 2>/dev/null
done

# Schedtune EAS (despacho prioritário instantâneo para núcleos Big/Prime)
echo 1 > /dev/stune/top-app/schedtune.prefer_idle 2>/dev/null
echo 10 > /dev/stune/top-app/schedtune.boost 2>/dev/null
echo 1 > /dev/stune/foreground/schedtune.prefer_idle 2>/dev/null

# RTG Boost para threads críticas de UI e Câmera (Snapdragon Related Thread Group)
echo 1056000 > /sys/devices/system/cpu/cpufreq/policy4/schedutil/rtg_boost_freq 2>/dev/null
echo 1190400 > /sys/devices/system/cpu/cpufreq/policy7/schedutil/rtg_boost_freq 2>/dev/null

# Cpuset partitioning & CFS cpu.shares (isolamento de prioridade de CPU)
echo 0-7 > /dev/cpuset/top-app/cpus 2>/dev/null
echo 0-6 > /dev/cpuset/foreground/cpus 2>/dev/null
echo 0-3 > /dev/cpuset/background/cpus 2>/dev/null
echo 0-3 > /dev/cpuset/system-background/cpus 2>/dev/null
echo 0-7 > /dev/cpuset/camera-daemon/cpus 2>/dev/null

echo 8192 > /dev/cpuctl/camera-daemon/cpu.shares 2>/dev/null
echo 8192 > /dev/cpuctl/top-app/cpu.shares 2>/dev/null
log "CPU & Cpuset: Particionamento, CFS shares 8192, Schedutil 1ms/10ms, Schedtune EAS e RTG Boost configurados."

# 2. GPU Adreno 650 (Estabilidade 120Hz)
echo 80 > /sys/class/kgsl/kgsl-3d0/idle_timer 2>/dev/null
echo 0 > /sys/class/kgsl/kgsl-3d0/throttling 2>/dev/null
echo 1 > /sys/class/kgsl/kgsl-3d0/force_bus_on 2>/dev/null
echo 1 > /sys/class/kgsl/kgsl-3d0/force_rail_on 2>/dev/null
echo 1 > /sys/class/kgsl/kgsl-3d0/force_clk_on 2>/dev/null
log "GPU: Adreno 650 calibrada para 120Hz estável sem perdas de frame."

# 3. SurfaceFlinger & 120Hz Fluidity
setprop debug.sf.early_phase_offset_ns 500000 2>/dev/null
setprop debug.sf.early_app_phase_offset_ns 500000 2>/dev/null
setprop debug.sf.early_gl_phase_offset_ns 3000000 2>/dev/null
setprop debug.sf.early_gl_app_phase_offset_ns 15000000 2>/dev/null
setprop debug.sf.high_fps_early_phase_offset_ns 500000 2>/dev/null
setprop debug.sf.high_fps_early_gl_phase_offset_ns 3000000 2>/dev/null
setprop debug.sf.high_fps_late_app_phase_offset_ns 1000000 2>/dev/null
setprop debug.sf.latch_unsignaled 1 2>/dev/null
setprop debug.sf.disable_backpressure 1 2>/dev/null
log "SurfaceFlinger: Offsets de 120Hz e latch_unsignaled aplicados para renderização sem jitter."

# 4. Gerenciamento de Memória RAM & Prevenção de Fragmentação Contígua (Snapdragon 865 - 8GB LPDDR5)
echo 0 > /proc/sys/vm/page-cluster 2>/dev/null
echo 20 > /proc/sys/vm/dirty_ratio 2>/dev/null
echo 10 > /proc/sys/vm/dirty_background_ratio 2>/dev/null
echo 100 > /proc/sys/vm/vfs_cache_pressure 2>/dev/null
echo 65536 > /proc/sys/vm/min_free_kbytes 2>/dev/null
echo 0 > /proc/sys/vm/extra_free_kbytes 2>/dev/null
echo 50 > /proc/sys/vm/watermark_scale_factor 2>/dev/null
echo 0 > /proc/sys/vm/watermark_boost_factor 2>/dev/null
echo 750 > /proc/sys/vm/extfrag_threshold 2>/dev/null

# Dirty writeback fluido para evitar engasgos de gravação em disco
echo 500 > /proc/sys/vm/dirty_expire_centisecs 2>/dev/null
echo 1000 > /proc/sys/vm/dirty_writeback_centisecs 2>/dev/null

(echo 3 > /proc/sys/vm/drop_caches; echo 1 > /proc/sys/vm/compact_memory) &
log "RAM: Gerenciamento calibrado (min_free=64MB, watermark=50, boost_factor=0, dirty writeback 5s/10s, anti-fragmentação)."

# 5. Multitarefa Samsung SLMK & ART Dalvik (Preservação de 8GB RAM)
setprop ro.config.dha_cached_max 32 2>/dev/null
setprop ro.config.dha_empty_max 24 2>/dev/null
setprop persist.device_config.slmkd_native.use_bg_keeping_policy true 2>/dev/null
setprop persist.device_config.slmkd_native.enable_preferred_apps true 2>/dev/null
setprop persist.device_config.slmkd_native.dha_cached_min 16 2>/dev/null
setprop persist.device_config.slmkd_native.swap_free_low_percentage 15 2>/dev/null

# Redução de pausas de Garbage Collection do ART
setprop dalvik.vm.heapminfree 4m 2>/dev/null
setprop dalvik.vm.heapmaxfree 16m 2>/dev/null
log "Multitarefa & ART: SLMK bg_keeping ativo, DHA 32 apps e margens de GC ampliadas."

# 6. Armazenamento UFS 3.1 & MicroSD (Solid-State Deadline Engine)
for d in sda sdb sdc sdd; do
    echo "deadline" > "/sys/block/$d/queue/scheduler" 2>/dev/null
    echo 100 > "/sys/block/$d/queue/iosched/read_expire" 2>/dev/null
    echo 1000 > "/sys/block/$d/queue/iosched/write_expire" 2>/dev/null
    echo 2 > "/sys/block/$d/queue/iosched/writes_starved" 2>/dev/null
    echo 16 > "/sys/block/$d/queue/iosched/fifo_batch" 2>/dev/null
    echo 0 > "/sys/block/$d/queue/iostats" 2>/dev/null
    echo 0 > "/sys/block/$d/queue/add_random" 2>/dev/null
    echo 2 > "/sys/block/$d/queue/rq_affinity" 2>/dev/null
    echo 256 > "/sys/block/$d/queue/nr_requests" 2>/dev/null
done
[ -d /sys/block/mmcblk0/queue ] && echo 1024 > /sys/block/mmcblk0/queue/read_ahead_kb 2>/dev/null
log "UFS 3.1: Agendador Deadline ativo (read_expire=100ms, write_expire=1000ms, rq_affinity=2, MicroSD 1MB)."

# 7. Samsung Input Booster (Latência de Toque e Rolagem Instantânea)
if [ -d /sys/class/input_booster/touch ]; then
    echo "200 1804800 1017 2 5" > /sys/class/input_booster/touch/head 2>/dev/null
    echo "500 1459200 1017 2 5" > /sys/class/input_booster/touch/tail 2>/dev/null
fi
log "Touch: Input Booster calibrado para 1.80GHz instantâneo ao primeiro toque."

# 8. Otimizações de Rede & TCP (Cubic + SACK + Fresh Handshake)
echo "cubic" > /proc/sys/net/ipv4/tcp_congestion_control 2>/dev/null
echo 1 > /proc/sys/net/ipv4/tcp_sack 2>/dev/null
echo 0 > /proc/sys/net/ipv4/tcp_ecn 2>/dev/null
echo 3 > /proc/sys/net/ipv4/tcp_fastopen 2>/dev/null
echo 1 > /proc/sys/net/ipv4/tcp_tw_reuse 2>/dev/null
echo 1 > /proc/sys/net/ipv4/tcp_no_metrics_save 2>/dev/null
echo 0 > /proc/sys/net/ipv4/tcp_slow_start_after_idle 2>/dev/null
echo 10000 > /proc/sys/net/core/netdev_max_backlog 2>/dev/null
log "Rede: TCP Cubic, SACK, FastOpen, no_metrics_save e velocidade sustentada sem idle drop."

# 9. Redução de Bloatware e Telemetria da Samsung & Qualcomm
setprop persist.sys.assert.enable false
setprop log.tag.stats_log OFF
setprop profiler.force_disable_err_rpt 1
setprop profiler.force_disable_ulog 1
setprop log.tag.APM_AudioPolicyManager OFF

# Desativa daemons de diagnóstico gastadores de CPU da Qualcomm
stop vendor.cnss_diag 2>/dev/null
stop vendor.ipacm-diag 2>/dev/null
setprop persist.vendor.sys.cnss.diag_enable 0 2>/dev/null

# Desativa definitivamente o Game Optimizing Service (GOS)
pm disable com.samsung.android.game.gos 2>/dev/null
am force-stop com.samsung.android.game.gos 2>/dev/null

# Desativa telemetria/bloats residuais
pm disable-user --user 0 com.sec.automation 2>/dev/null
pm disable-user --user 0 com.android.egg 2>/dev/null

# Desativa tracing do Perfetto em segundo plano
setprop persist.traced.enable 0 2>/dev/null
stop traced 2>/dev/null
stop traced_probes 2>/dev/null
log "Telemetria: cnss_diag, ipacm-diag, GOS, sec.automation e Perfetto desativados."

# 10. Bateria & Standby (Doze Deep Sleep no Android 13)
device_idle_constants="inactive_to=180000,sensing_to=0,locating_to=0,location_accuracy=20.0,motion_inactive_to=0,idle_after_inactive_to=0,idle_pending_to=60000,max_idle_pending_to=120000,idle_pending_factor=2.0,idle_to=3600000,max_idle_to=21600000,idle_factor=2.0,min_time_to_alarm=3600000,max_temp_app_allowlist_duration_ms=60000,mms_temp_app_allowlist_duration_ms=60000,sms_temp_app_allowlist_duration_ms=60000,notification_allowlist_duration_ms=60000"
settings put global device_idle_constants "$device_idle_constants" 2>/dev/null
settings put global wifi_scan_throttle_enabled 1 2>/dev/null
settings put global adaptive_battery_management_enabled 1 2>/dev/null
settings put global wifi_networks_available_notification_on 0 2>/dev/null

# Remove bloats do sistema da lista branca do Doze
dumpsys deviceidle whitelist -com.samsung.android.game.gos 2>/dev/null
dumpsys deviceidle whitelist -com.sec.android.app.safetyassurance 2>/dev/null
dumpsys deviceidle whitelist -com.samsung.android.kgclient 2>/dev/null
log "Bateria: Doze Deep Sleep acelerado, spam de Wi-Fi desativado e limpeza de whitelist."

# 11. Firewall Zero-Network para dynamicSpot
apply_dynamicspot_firewall() {
    DSPOT_UID=$(pm list packages -U 2>/dev/null | grep com.jamworks.dynamicspot | awk -F"uid:" '{print $2}' | cut -d" " -f1)
    if [ -n "$DSPOT_UID" ]; then
        iptables -C OUTPUT -m owner --uid-owner "$DSPOT_UID" -j DROP 2>/dev/null || iptables -I OUTPUT -m owner --uid-owner "$DSPOT_UID" -j DROP
        ip6tables -C OUTPUT -m owner --uid-owner "$DSPOT_UID" -j DROP 2>/dev/null || ip6tables -I OUTPUT -m owner --uid-owner "$DSPOT_UID" -j DROP
    fi
}
apply_dynamicspot_firewall
log "Segurança: Firewall de rede ativado para dynamicSpot."

# 12. Calibração de Preferências da Câmera (Eliminação de OCR, IA de Cena e Embelezamento em Preview)
CAMX_DIR="/data/vendor/camera"
rm -f "$CAMX_DIR/camxoverridesettings.txt" 2>/dev/null
resetprop -p -d persist.vendor.camera.eisv3enable 2>/dev/null || resetprop -d persist.vendor.camera.eisv3enable 2>/dev/null || true
resetprop -p -d persist.vendor.camera.EISV3Enable 2>/dev/null || resetprop -d persist.vendor.camera.EISV3Enable 2>/dev/null || true

CAM_PREFS="/data/data/com.sec.android.app.camera/shared_prefs/com.sec.android.app.camera_preferences.xml"
if [ -f "$CAM_PREFS" ]; then
    for key in qr_code_detection scene_optimizer additional_scene_document_scan front_photo_beauty_type back_photo_beauty_type front_beauty_smoothness_level back_beauty_smoothness_level adaptive_lens_mode video_adaptive_lens_mode video_stabilisation; do
        if grep -q "name=\"$key\"" "$CAM_PREFS"; then
            sed -i "s|<string name=\"$key\">.*</string>|<string name=\"$key\">0</string>|g" "$CAM_PREFS" 2>/dev/null
        else
            sed -i "s|</map>|    <string name=\"$key\">0</string>\n</map>|" "$CAM_PREFS" 2>/dev/null
        fi
    done
fi
log "Câmera: Preferências calibradas (QR Code OCR desligado, Scene AI desligado, Beauty desligado, OIS 100% ativo)."

# 13. Priorização de Daemons Críticos (Biometria, Áudio DSP e Câmera)
boost_critical_daemons() {
    # 1. Leitor Biométrico Óptico de Digital (nice -20)
    fpid=$(pidof vendor.samsung.hardware.biometrics.fingerprint@3.0-service 2>/dev/null)
    if [ -n "$fpid" ]; then
        renice -n "-20" "$fpid" 2>/dev/null
        for tid in /proc/$fpid/task/*; do
            renice -n "-20" "${tid##*/}" 2>/dev/null
        done
    fi

    # 2. Pipeline de Áudio e DSP Qualcomm (nice -20)
    for apid in $(pidof audioserver vendor.audio-hal adsprpcd 2>/dev/null); do
        renice -n "-20" "$apid" 2>/dev/null
        for tid in /proc/$apid/task/*; do
            renice -n "-20" "${tid##*/}" 2>/dev/null
        done
    done

    # 3. Hardware de Câmera e Codecs de Vídeo (nice -20 real-time)
    for cpid in $(pidof com.sec.android.app.camera vendor.samsung.hardware.camera.provider@4.0-service_64 cameraserver media.codec media.swcodec 2>/dev/null); do
        renice -n "-20" "$cpid" 2>/dev/null
        for tid in /proc/$cpid/task/*; do
            renice -n "-20" "${tid##*/}" 2>/dev/null
        done
    done
}
boost_critical_daemons
log "Priorização: Biometria óptica (-20), Áudio DSP (-20) e Câmera (-20) configurados em tempo real."

# 14. Limpeza Autônoma de Backups Redundantes do WhatsApp (Proteção de Armazenamento)
clean_whatsapp_backups() {
    WA_DB_DIR="/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Databases"
    if [ -d "$WA_DB_DIR" ]; then
        find "$WA_DB_DIR" -maxdepth 1 -name "msgstore-*.1.db.crypt14" -mtime +1d -delete 2>/dev/null
    fi
}
clean_whatsapp_backups
log "WhatsApp: Rotina de retenção de backups ativada (preserva ativo + último histórico)."

# 15. Sentinela de Câmera Nativamente Orientado a Eventos (Zero Polling / Futex de Baixa Latência)
log "Sentinela adaptativo operacional..."

# Estado inicial ao iniciar o serviço
if [ "$(resetprop service.camera.running 2>/dev/null)" = "1" ]; then
    echo 1612800 > /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq 2>/dev/null
    echo 2246400 > /sys/devices/system/cpu/cpufreq/policy4/scaling_min_freq 2>/dev/null
    echo 2649600 > /sys/devices/system/cpu/cpufreq/policy7/scaling_min_freq 2>/dev/null
    echo 35 > /dev/stune/top-app/schedtune.boost 2>/dev/null
    echo 490000000 > /sys/class/kgsl/kgsl-3d0/devfreq/min_freq 2>/dev/null
    echo 100 > /sys/class/kgsl/kgsl-3d0/idle_timer 2>/dev/null
    boost_critical_daemons
else
    echo 300000 > /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq 2>/dev/null
    echo 710400 > /sys/devices/system/cpu/cpufreq/policy4/scaling_min_freq 2>/dev/null
    echo 844800 > /sys/devices/system/cpu/cpufreq/policy7/scaling_min_freq 2>/dev/null
    echo 305000000 > /sys/class/kgsl/kgsl-3d0/devfreq/min_freq 2>/dev/null
    echo 80 > /sys/class/kgsl/kgsl-3d0/idle_timer 2>/dev/null
fi

# Sentinela de Abertura e Fechamento da Câmera (0ms de latência via futex)
(
    while true; do
        # 1. Bloqueia em repouso absoluto (0% CPU) até a câmera ser iniciada
        resetprop -w service.camera.running 0 >/dev/null 2>&1
        
        # RAMP INSTANTÂNEO DE HARDWARE (Fluidez extrema no preview e alternância de lentes 0.5x/1.0x/3.0x)
        echo 1612800 > /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq 2>/dev/null
        echo 2246400 > /sys/devices/system/cpu/cpufreq/policy4/scaling_min_freq 2>/dev/null
        echo 2649600 > /sys/devices/system/cpu/cpufreq/policy7/scaling_min_freq 2>/dev/null
        echo 35 > /dev/stune/top-app/schedtune.boost 2>/dev/null
        echo 490000000 > /sys/class/kgsl/kgsl-3d0/devfreq/min_freq 2>/dev/null
        echo 100 > /sys/class/kgsl/kgsl-3d0/idle_timer 2>/dev/null
        boost_critical_daemons
        
        # 2. Bloqueia em repouso absoluto durante o uso da câmera até ela ser fechada
        resetprop -w service.camera.running 1 >/dev/null 2>&1
        
        # RETORNO A REPOUSO IMEDIATO (Economia total de bateria ao fechar a câmera)
        echo 300000 > /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq 2>/dev/null
        echo 710400 > /sys/devices/system/cpu/cpufreq/policy4/scaling_min_freq 2>/dev/null
        echo 844800 > /sys/devices/system/cpu/cpufreq/policy7/scaling_min_freq 2>/dev/null
        echo 10 > /dev/stune/top-app/schedtune.boost 2>/dev/null
        echo 305000000 > /sys/class/kgsl/kgsl-3d0/devfreq/min_freq 2>/dev/null
        echo 80 > /sys/class/kgsl/kgsl-3d0/idle_timer 2>/dev/null
        (echo 1 > /proc/sys/vm/compact_memory) &
    done
) &

# Sentinela de Gravação 4K 60fps (Zero Polling / Futex)
(
    while true; do
        # Aguarda início da gravação
        resetprop -w service.camera.rec.running 0 >/dev/null 2>&1
        
        # RAMP 4K60 ULTRA-BOOST (CPU Big 2.42GHz, Prime 2.84GHz, GPU 587MHz)
        echo 2419200 > /sys/devices/system/cpu/cpufreq/policy4/scaling_min_freq 2>/dev/null
        echo 2841600 > /sys/devices/system/cpu/cpufreq/policy7/scaling_min_freq 2>/dev/null
        echo 587000000 > /sys/class/kgsl/kgsl-3d0/devfreq/min_freq 2>/dev/null
        
        # Aguarda parada da gravação
        resetprop -w service.camera.rec.running 1 >/dev/null 2>&1
        
        # Se a câmera ainda estiver aberta em preview, restaura o patamar de preview
        if [ "$(resetprop service.camera.running 2>/dev/null)" = "1" ]; then
            echo 1612800 > /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq 2>/dev/null
            echo 2246400 > /sys/devices/system/cpu/cpufreq/policy4/scaling_min_freq 2>/dev/null
            echo 2649600 > /sys/devices/system/cpu/cpufreq/policy7/scaling_min_freq 2>/dev/null
            echo 490000000 > /sys/class/kgsl/kgsl-3d0/devfreq/min_freq 2>/dev/null
        fi
    done
) &

# Sentinela de Manutenção Periódica e Sono Profundo
(
    cycle_count=0
    trim_day=0
    while true; do
        sleep 60

        screen_asleep=0
        if dumpsys power 2>/dev/null | grep -q "mWakefulness=Asleep"; then
            screen_asleep=1
        fi

        curr_swappiness=$(cat /proc/sys/vm/swappiness 2>/dev/null)
        if [ -n "$curr_swappiness" ] && [ "$curr_swappiness" -gt 60 ]; then
            echo 60 > /proc/sys/vm/swappiness 2>/dev/null
        fi

        stop vendor.cnss_diag 2>/dev/null
        stop vendor.ipacm-diag 2>/dev/null
        pm disable com.samsung.android.game.gos 2>/dev/null
        apply_dynamicspot_firewall
        boost_critical_daemons

        # Desfragmentação preventiva de CMA se memória contígua estiver baixa (< 60MB)
        if [ "$(resetprop service.camera.running 2>/dev/null)" != "1" ]; then
            curr_cma_free=$(awk '/CmaFree:/ {print $2}' /proc/meminfo 2>/dev/null)
            if [ -n "$curr_cma_free" ] && [ "$curr_cma_free" -lt 60000 ]; then
                (echo 3 > /proc/sys/vm/drop_caches; echo 1 > /proc/sys/vm/compact_memory) &
            else
                (echo 1 > /proc/sys/vm/compact_memory) &
            fi
        fi

        # Retenção de backups do WhatsApp a cada 6 horas (360 x 60s)
        cycle_count=$((cycle_count + 1))
        if [ "$cycle_count" -ge 360 ]; then
            cycle_count=0
            clean_whatsapp_backups
        fi

        # Fstrim silencioso a cada 24 horas durante sono profundo
        if [ "$screen_asleep" -eq 1 ]; then
            trim_day=$((trim_day + 1))
            if [ "$trim_day" -ge 1440 ]; then
                trim_day=0
                sm fstrim 2>/dev/null
            fi
        fi
    done
) &
log "=== Otimizações v4.1 concluídas com sucesso. Sentinela operacional. ==="
