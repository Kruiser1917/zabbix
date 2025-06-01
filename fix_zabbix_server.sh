#!/bin/bash

#=======================================================================
# Скрипт исправления Zabbix Server
# Выполнять на сервере под root
#=======================================================================

echo "🔧 Исправляем Zabbix Server..."

# 1. Установить Zabbix сервер если не установлен
echo "1. Устанавливаем Zabbix Server..."
apt update
apt install -y zabbix-server-mysql

# 2. Настроить MySQL если не настроен
echo "2. Настраиваем MySQL..."
systemctl start mysql
systemctl enable mysql

# Создать базу данных если не создана
mysql -e "CREATE DATABASE IF NOT EXISTS zabbix character set utf8mb4 collate utf8mb4_bin;"
mysql -e "CREATE USER IF NOT EXISTS 'zabbix'@'localhost' IDENTIFIED BY 'zabbix_pass';"
mysql -e "GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'localhost';"
mysql -e "SET GLOBAL log_bin_trust_function_creators = 1;"
mysql -e "FLUSH PRIVILEGES;"

# 3. Импортировать схему если не импортирована
echo "3. Проверяем и импортируем схему базы данных..."
TABLE_COUNT=$(mysql -uzabbix -pzabbix_pass zabbix -e "SHOW TABLES;" 2>/dev/null | wc -l)
if [ "$TABLE_COUNT" -lt 5 ]; then
    echo "Импортируем схему..."
    zcat /usr/share/doc/zabbix-sql-scripts/mysql/server.sql.gz | mysql -uzabbix -pzabbix_pass zabbix
else
    echo "Схема уже импортирована"
fi

# 4. Настроить конфигурацию Zabbix сервера
echo "4. Настраиваем конфигурацию Zabbix сервера..."
sed -i 's/# DBPassword=/DBPassword=zabbix_pass/' /etc/zabbix/zabbix_server.conf
sed -i 's/DBPassword=$/DBPassword=zabbix_pass/' /etc/zabbix/zabbix_server.conf

# 5. Запустить Zabbix сервер
echo "5. Запускаем Zabbix сервер..."
systemctl stop zabbix-server
systemctl start zabbix-server
systemctl enable zabbix-server

# 6. Ждем запуска
echo "6. Ждем запуска сервера..."
sleep 10

# 7. Проверить статусы
echo "7. Проверяем статусы служб..."
echo "=== MySQL ==="
systemctl status mysql --no-pager -l
echo ""
echo "=== Zabbix Server ==="
systemctl status zabbix-server --no-pager -l
echo ""

# 8. Проверить порты
echo "8. Проверяем порты..."
echo "=== Порт 10051 (Zabbix Server) ==="
ss -tuln | grep 10051
echo ""
echo "=== Порт 80 (Apache) ==="
ss -tuln | grep :80

# 9. Проверить логи
echo "9. Последние записи в логе Zabbix сервера..."
tail -10 /var/log/zabbix/zabbix_server.log

echo ""
echo "🎉 Исправление завершено!"
echo "Проверьте:"
echo "- Веб-интерфейс: http://$(hostname -I | awk '{print $1}')/zabbix/"
echo "- Порт 10051 должен быть открыт для агентов" 