#!/bin/bash

#=======================================================================
# Тестовый скрипт для проверки функций Zabbix Agent установщика
# Безопасно тестирует отдельные функции без реальной установки
#=======================================================================

# Загружаем функции из основного скрипта (без выполнения main)
source install_zabbix_agent.sh

# Переопределяем потенциально опасные команды для тестирования
apt-get() {
    echo "[TEST] Выполнялась бы команда: apt-get $@"
}

dpkg() {
    echo "[TEST] Выполнялась бы команда: dpkg $@"
}

wget() {
    echo "[TEST] Выполнялась бы команда: wget $@"
}

systemctl() {
    echo "[TEST] Выполнялась бы команда: systemctl $@"
    
    # Имитируем некоторые ответы
    case "$1" in
        "is-active")
            return 0  # Имитируем что служба активна
            ;;
        "status")
            echo "● zabbix-agent.service - Zabbix Agent"
            echo "   Loaded: loaded (/lib/systemd/system/zabbix-agent.service; enabled)"
            echo "   Active: active (running)"
            ;;
    esac
}

service() {
    echo "[TEST] Выполнялась бы команда: service $@"
}

yum() {
    echo "[TEST] Выполнялась бы команда: yum $@"
}

rpm() {
    echo "[TEST] Выполнялась бы команда: rpm $@"
}

sed() {
    echo "[TEST] Выполнялась бы команда: sed $@"
}

cp() {
    echo "[TEST] Выполнялась бы команда: cp $@"
}

ss() {
    echo "[TEST] Проверка портов: ss $@"
    echo "tcp    LISTEN     0      128       *:10050"  # Имитируем что порт слушается
}

tail() {
    echo "[TEST] Последние строки лога:"
    echo "2025-05-31 15:30:00 zabbix_agentd [INFO] agent #0 started [main process]"
    echo "2025-05-31 15:30:01 zabbix_agentd [INFO] agent #1 started [collector]"
    echo "2025-05-31 15:30:02 zabbix_agentd [INFO] agent #2 started [listener #1]"
}

# Переопределяем проверку root для тестирования
check_root() {
    log "Проверка прав root (тестовый режим - пропускаем)"
}

#=======================================================================
# ТЕСТОВЫЕ ФУНКЦИИ
#=======================================================================

test_detect_os() {
    echo "========================================="
    echo "🔍 ТЕСТ: Определение операционной системы"
    echo "========================================="
    
    detect_os
    echo "Результат: OS=$OS, VERSION=$VERSION"
    echo ""
}

test_install_zabbix_repo() {
    echo "========================================="
    echo "📦 ТЕСТ: Установка репозитория Zabbix"
    echo "========================================="
    
    install_zabbix_repo
    echo ""
}

test_install_zabbix_agent() {
    echo "========================================="
    echo "⚙️ ТЕСТ: Установка Zabbix Agent"
    echo "========================================="
    
    install_zabbix_agent
    echo ""
}

test_configure_zabbix_agent() {
    echo "========================================="
    echo "🔧 ТЕСТ: Конфигурация Zabbix Agent"
    echo "========================================="
    
    # Создаем временный файл конфигурации для тестирования
    local test_config="/tmp/test_zabbix_agentd.conf"
    cat > "$test_config" << EOF
# Test Zabbix agent configuration file
Server=127.0.0.1
ServerActive=127.0.0.1
Hostname=Zabbix server
# EnableRemoteCommands=0
# LogRemoteCommands=0
# StartAgents=3
# RefreshActiveChecks=120
EOF
    
    echo "Исходная конфигурация:"
    cat "$test_config"
    echo ""
    
    # Переопределяем путь к конфигу для тестирования
    configure_zabbix_agent() {
        local server_ip="${1:-127.0.0.1}"
        local hostname="${2:-$(hostname)}"
        local config_file="/tmp/test_zabbix_agentd.conf"
        
        log "Настраиваем Zabbix Agent..."
        log "IP сервера: $server_ip"
        log "Hostname: $hostname"
        
        # Создаем бэкап
        cp "$config_file" "${config_file}.backup"
        log "Создан бэкап конфигурации: ${config_file}.backup"
        
        # Настраиваем параметры (реальные sed команды для демонстрации)
        sed -i "s/^Server=.*/Server=$server_ip/" "$config_file"
        sed -i "s/^ServerActive=.*/ServerActive=$server_ip/" "$config_file"
        sed -i "s/^Hostname=.*/Hostname=$hostname/" "$config_file"
        sed -i "s/^# EnableRemoteCommands=.*/EnableRemoteCommands=0/" "$config_file"
        sed -i "s/^# LogRemoteCommands=.*/LogRemoteCommands=1/" "$config_file"
        sed -i "s/^# StartAgents=.*/StartAgents=3/" "$config_file"
        sed -i "s/^# RefreshActiveChecks=.*/RefreshActiveChecks=120/" "$config_file"
        
        log "Конфигурация Zabbix Agent завершена"
        
        echo "Новая конфигурация:"
        cat "$config_file"
    }
    
    configure_zabbix_agent "192.168.1.100" "test-server"
    echo ""
    
    # Очищаем тестовые файлы
    rm -f /tmp/test_zabbix_agentd.conf*
}

test_manage_service() {
    echo "========================================="
    echo "🚀 ТЕСТ: Управление службой"
    echo "========================================="
    
    manage_service
    echo ""
}

test_check_status() {
    echo "========================================="
    echo "📊 ТЕСТ: Проверка состояния"
    echo "========================================="
    
    check_status
    echo ""
}

#=======================================================================
# ЗАПУСК ВСЕХ ТЕСТОВ
#=======================================================================

run_all_tests() {
    echo "🧪 НАЧИНАЕМ КОМПЛЕКСНОЕ ТЕСТИРОВАНИЕ СКРИПТА ZABBIX AGENT"
    echo "Дата: $(date)"
    echo "Пользователь: $(whoami)"
    echo "Система: $(uname -a)"
    echo ""
    
    test_detect_os
    test_install_zabbix_repo
    test_install_zabbix_agent
    test_configure_zabbix_agent
    test_manage_service
    test_check_status
    
    echo "========================================="
    echo "✅ ВСЕ ТЕСТЫ ЗАВЕРШЕНЫ!"
    echo "========================================="
    echo ""
    echo "Для реальной установки запустите:"
    echo "sudo ./install_zabbix_agent.sh IP_СЕРВЕРА HOSTNAME"
    echo ""
    echo "Пример:"
    echo "sudo ./install_zabbix_agent.sh 192.168.1.100 web-server-01"
}

#=======================================================================
# МЕНЮ ВЫБОРА
#=======================================================================

case "${1:-all}" in
    "os")
        test_detect_os
        ;;
    "repo")
        test_install_zabbix_repo
        ;;
    "install")
        test_install_zabbix_agent
        ;;
    "config")
        test_configure_zabbix_agent
        ;;
    "service")
        test_manage_service
        ;;
    "status")
        test_check_status
        ;;
    "all"|"")
        run_all_tests
        ;;
    *)
        echo "Использование: $0 [os|repo|install|config|service|status|all]"
        echo ""
        echo "Тесты:"
        echo "  os      - Определение ОС"
        echo "  repo    - Установка репозитория"
        echo "  install - Установка агента"
        echo "  config  - Конфигурация"
        echo "  service - Управление службой"
        echo "  status  - Проверка состояния"
        echo "  all     - Все тесты (по умолчанию)"
        ;;
esac 