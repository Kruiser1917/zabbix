#!/bin/bash

#=======================================================================
# Универсальный скрипт установки Zabbix Agent
# Поддерживаемые CentOS, RedOS, Astra Linux, Alt Linux, Debian, Ubuntu
#=======================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' 

# Функция логирования
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}" >&2
}

warn() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

# Проверка прав root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "Скрипт должен запускаться от root пользователя"
        exit 1
    fi
}

# Определение операционной системы
detect_os() {
    log "Определяем операционную систему..."
    
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$ID
        VERSION=$VERSION_ID
    elif [[ -f /etc/redhat-release ]]; then
        OS="rhel"
        VERSION=$(grep -oE '[0-9]+\.[0-9]+' /etc/redhat-release | head -1)
    else
        error "Не удалось определить операционную систему"
        exit 1
    fi
    
    log "Обнаружена ОС: $OS $VERSION"
}

# Установка репозитория Zabbix
install_zabbix_repo() {
    log "Устанавливаем репозиторий Zabbix..."
    
    case "$OS" in
        "ubuntu"|"debian")
            apt-get update
            apt-get install -y wget curl gnupg2
            
            if [[ "$OS" == "ubuntu" ]]; then
                REPO_OS="ubuntu"
                REPO_VERSION=$(echo $VERSION | cut -d. -f1,2)
            else
                REPO_OS="debian"
                REPO_VERSION=$(echo $VERSION | cut -d. -f1)
            fi
            
            wget "https://repo.zabbix.com/zabbix/6.4/${REPO_OS}/pool/main/z/zabbix-release/zabbix-release_6.4-1+${REPO_OS}${REPO_VERSION}_all.deb"
            dpkg -i "zabbix-release_6.4-1+${REPO_OS}${REPO_VERSION}_all.deb"
            apt-get update
            ;;
            
        "centos"|"rhel"|"redos"|"almalinux"|"rocky")
            yum install -y epel-release wget curl
            
            MAJOR_VERSION=$(echo $VERSION | cut -d. -f1)
            
            rpm -Uvh "https://repo.zabbix.com/zabbix/6.4/rhel/${MAJOR_VERSION}/x86_64/zabbix-release-6.4-1.el${MAJOR_VERSION}.noarch.rpm"
            yum clean all
            ;;
            
        "astra")
            apt-get update
            apt-get install -y wget curl gnupg2
            
            REPO_VERSION="11"
            wget "https://repo.zabbix.com/zabbix/6.4/debian/pool/main/z/zabbix-release/zabbix-release_6.4-1+debian${REPO_VERSION}_all.deb"
            dpkg -i "zabbix-release_6.4-1+debian${REPO_VERSION}_all.deb"
            apt-get update
            ;;
            
        "altlinux"|"alt")
            apt-get update
            apt-get install -y wget curl
            
            warn "Alt Linux обнаружен. Используем альтернативный метод установки."
            ;;
            
        *)
            error "Неподдерживаемая операционная система: $OS"
            exit 1
            ;;
    esac
    
    log "Репозиторий Zabbix успешно установлен"
}

install_zabbix_agent() {
    log "Устанавливаем Zabbix Agent..."
    
    case "$OS" in
        "ubuntu"|"debian"|"astra")
            apt-get install -y zabbix-agent
            ;;
        "centos"|"rhel"|"redos"|"almalinux"|"rocky")
            yum install -y zabbix-agent
            ;;
        "altlinux"|"alt")
            apt-get install -y zabbix-agent || {
                warn "Стандартная установка не удалась. Пробуем альтернативный метод..."
                return 1
            }
            ;;
        *)
            error "Установка для $OS не поддерживается"
            return 1
            ;;
    esac
    
    log "Zabbix Agent успешно установлен"
}

configure_zabbix_agent() {
    local server_ip="${1:-127.0.0.1}"
    local hostname="${2:-$(hostname)}"
    
    log "Настраиваем Zabbix Agent..."
    log "IP сервера: $server_ip"
    log "Hostname: $hostname"
    
    local config_file="/etc/zabbix/zabbix_agentd.conf"
    
    if [[ ! -f "${config_file}.backup" ]]; then
        cp "$config_file" "${config_file}.backup"
        log "Создан бэкап конфигурации: ${config_file}.backup"
    fi
    
    sed -i "s/^Server=.*/Server=$server_ip/" "$config_file"
    sed -i "s/^ServerActive=.*/ServerActive=$server_ip/" "$config_file"
    sed -i "s/^Hostname=.*/Hostname=$hostname/" "$config_file"
    
    sed -i "s/^# EnableRemoteCommands=.*/EnableRemoteCommands=0/" "$config_file"
    sed -i "s/^# LogRemoteCommands=.*/LogRemoteCommands=1/" "$config_file"
    
    
    sed -i "s/^# StartAgents=.*/StartAgents=3/" "$config_file"
    sed -i "s/^# RefreshActiveChecks=.*/RefreshActiveChecks=120/" "$config_file"
    
    log "Конфигурация Zabbix Agent завершена"
}


manage_service() {
    log "Запускаем и настраиваем автозагрузку службы..."
    
    if command -v systemctl &> /dev/null; then
        # systemd
        systemctl daemon-reload
        systemctl enable zabbix-agent
        systemctl restart zabbix-agent
        
        
        if systemctl is-active --quiet zabbix-agent; then
            log "Служба Zabbix Agent успешно запущена (systemd)"
        else
            error "Не удалось запустить службу Zabbix Agent"
            return 1
        fi
        
    elif command -v service &> /dev/null; then
        # SysV Init
        service zabbix-agent start
        
        
        if command -v chkconfig &> /dev/null; then
            chkconfig zabbix-agent on
        elif command -v update-rc.d &> /dev/null; then
            update-rc.d zabbix-agent enable
        fi
        
        log "Служба Zabbix Agent запущена (SysV Init)"
    else
        error "Не удалось определить систему управления службами"
        return 1
    fi
}

# Проверка состояния
check_status() {
    log "Проверяем состояние Zabbix Agent..."
    
    #  статус службы
    if command -v systemctl &> /dev/null; then
        systemctl status zabbix-agent --no-pager
    else
        service zabbix-agent status
    fi
    
    #  сетевое подключение
    if ss -tuln | grep -q ":10050"; then
        log "Zabbix Agent слушает на порту 10050 ✓"
    else
        warn "Zabbix Agent не слушает на порту 10050"
    fi
    
    #  логи
    local log_file="/var/log/zabbix/zabbix_agentd.log"
    if [[ -f "$log_file" ]]; then
        log "Последние записи в логе:"
        tail -5 "$log_file"
    fi
}

#  функция
main() {
    local server_ip="${1}"
    local hostname="${2}"
    
    echo "======================================="
    echo "   Установка Zabbix Agent v1.0"
    echo "======================================="
    
    
    if [[ -z "$server_ip" ]]; then
        read -p "Введите IP адрес Zabbix сервера: " server_ip
        [[ -z "$server_ip" ]] && server_ip="127.0.0.1"
    fi
    
    if [[ -z "$hostname" ]]; then
        read -p "Введите hostname агента [$(hostname)]: " hostname
        [[ -z "$hostname" ]] && hostname="$(hostname)"
    fi
    
    
    check_root
    detect_os
    install_zabbix_repo
    install_zabbix_agent
    configure_zabbix_agent "$server_ip" "$hostname"
    manage_service
    check_status
    
    echo "======================================="
    log "Установка Zabbix Agent завершена успешно!"
    log "IP сервера: $server_ip"
    log "Hostname: $hostname"
    log "Конфиг: /etc/zabbix/zabbix_agentd.conf"
    echo "======================================="
}

# Обработка параметров командной строки
case "${1:-}" in
    --help|-h)
        echo "Использование: $0 [IP_СЕРВЕРА] [HOSTNAME]"
        echo "Пример: $0 192.168.1.100 web-server-01"
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac 