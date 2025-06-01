#!/bin/bash

#=======================================================================
# Скрипт настройки веб-интерфейса Zabbix
# Выполнять на сервере под root
#=======================================================================

echo "🔧 Настройка веб-интерфейса Zabbix..."

# 1. Включить конфигурацию Zabbix в Apache
echo "1. Включаем конфигурацию Zabbix в Apache..."
a2enconf zabbix-frontend-php

# 2. Включить нужные модули PHP
echo "2. Включаем модули PHP..."
a2enmod rewrite
phpenmod bcmath gd mbstring

# 3. Перезапустить Apache
echo "3. Перезапускаем Apache..."
systemctl reload apache2
systemctl restart apache2

# 4. Установить и настроить базу данных
echo "4. Устанавливаем MySQL сервер..."
apt update
apt install -y mysql-server zabbix-server-mysql

# 5. Создать базу данных
echo "5. Создаем базу данных Zabbix..."
mysql -e "CREATE DATABASE zabbix character set utf8mb4 collate utf8mb4_bin;"
mysql -e "CREATE USER 'zabbix'@'localhost' IDENTIFIED BY 'zabbix_pass';"
mysql -e "GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'localhost';"
mysql -e "SET GLOBAL log_bin_trust_function_creators = 1;"

# 6. Импортировать схему базы данных
echo "6. Импортируем схему базы данных..."
zcat /usr/share/doc/zabbix-sql-scripts/mysql/server.sql.gz | mysql -uzabbix -pzabbix_pass zabbix

# 7. Настроить конфигурацию Zabbix сервера
echo "7. Настраиваем конфигурацию Zabbix сервера..."
sed -i 's/# DBPassword=/DBPassword=zabbix_pass/' /etc/zabbix/zabbix_server.conf

# 8. Запустить Zabbix сервер
echo "8. Запускаем Zabbix сервер..."
systemctl restart zabbix-server
systemctl enable zabbix-server

# 9. Перезапустить Apache
echo "9. Финальный перезапуск Apache..."
systemctl restart apache2

# 10. Проверить статусы
echo "10. Проверяем статусы служб..."
echo "=== Apache ==="
systemctl status apache2 --no-pager -l
echo ""
echo "=== Zabbix Server ==="
systemctl status zabbix-server --no-pager -l
echo ""
echo "=== MySQL ==="
systemctl status mysql --no-pager -l

echo ""
echo "🎉 Настройка завершена!"
echo "Веб-интерфейс должен быть доступен по адресу:"
echo "http://$(hostname -I | awk '{print $1}')/zabbix/"
echo ""
echo "Логин по умолчанию: Admin"
echo "Пароль по умолчанию: zabbix" 