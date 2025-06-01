#!/bin/bash

echo "🧪 ПРОСТОЕ ТЕСТИРОВАНИЕ СКРИПТА ZABBIX AGENT"
echo "============================================="

echo "1. Проверяем определение ОС:"
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    echo "   ОС: $ID"
    echo "   Версия: $VERSION_ID"
    echo "   Полное название: $PRETTY_NAME"
else
    echo "   ❌ Файл /etc/os-release не найден"
fi

echo ""
echo "2. Проверяем доступность команд:"

commands=("systemctl" "apt-get" "wget" "curl" "sed")
for cmd in "${commands[@]}"; do
    if command -v "$cmd" &> /dev/null; then
        echo "   ✅ $cmd доступен"
    else
        echo "   ❌ $cmd не найден"
    fi
done

echo ""
echo "3. Проверяем права пользователя:"
echo "   Текущий пользователь: $(whoami)"
echo "   UID: $(id -u)"
if [[ $EUID -eq 0 ]]; then
    echo "   ✅ Запущено от root"
else
    echo "   ⚠️  Запущено от обычного пользователя (для реальной установки нужен sudo)"
fi

echo ""
echo "4. Информация о системе:"
echo "   Архитектура: $(uname -m)"
echo "   Ядро: $(uname -r)"
echo "   Хостнейм: $(hostname)"

echo ""
echo "5. Тестируем логику определения репозитория для Ubuntu:"
OS="ubuntu"
VERSION="24.04"
echo "   Для Ubuntu $VERSION будет использоваться:"
echo "   REPO_OS=$OS"
echo "   REPO_VERSION=$(echo $VERSION | cut -d. -f1,2)"
echo "   URL: https://repo.zabbix.com/zabbix/6.4/ubuntu/pool/main/z/zabbix-release/"

echo ""
echo "6. Проверяем возможность создания конфигурации:"
TEST_CONFIG="/tmp/test_config.conf"
cat > "$TEST_CONFIG" << 'EOF'
Server=127.0.0.1
ServerActive=127.0.0.1
Hostname=test-hostname
EOF

echo "   Создан тестовый конфиг:"
cat "$TEST_CONFIG"

echo ""
echo "   Применяем изменения (демонстрация):"
sed "s/^Server=.*/Server=192.168.1.100/" "$TEST_CONFIG"
echo ""

# Очищаем
rm -f "$TEST_CONFIG"

echo "============================================="
echo "✅ ТЕСТИРОВАНИЕ ЗАВЕРШЕНО!"
echo ""
echo "Для реальной установки Zabbix Agent:"
echo "sudo ./install_zabbix_agent.sh 192.168.1.100 my-hostname"
echo ""
echo "Или интерактивно:"
echo "sudo ./install_zabbix_agent.sh" 