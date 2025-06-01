# 🔧 Универсальный скрипт установки Zabbix Agent

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/Bash-4%2B-green.svg)](https://www.gnu.org/software/bash/)
[![Zabbix](https://img.shields.io/badge/Zabbix-6.4-blue.svg)](https://www.zabbix.com/)

Автоматический скрипт для установки и настройки Zabbix Agent на различных Linux дистрибутивах.

## 🎯 Поддерживаемые операционные системы

- ✅ **Ubuntu** (18.04, 20.04, 22.04, 24.04)
- ✅ **Debian** (9, 10, 11, 12)
- ✅ **CentOS** (7, 8, 9)
- ✅ **RedOS** (7.3+)
- ✅ **Astra Linux**
- ✅ **Alt Linux**
- ✅ **AlmaLinux** / **Rocky Linux**

## 🚀 Быстрый старт

### Установка с настройками по умолчанию

```bash
# Скачать и запустить скрипт
wget https://raw.githubusercontent.com/Kruiser1917/zabbix/main/install_zabbix_agent.sh
chmod +x install_zabbix_agent.sh
sudo ./install_zabbix_agent.sh
```

### Установка с указанием сервера Zabbix

```bash
sudo ./install_zabbix_agent.sh 192.168.1.100 my-server-hostname
```

### Тестовый режим (без фактической установки)

```bash
./install_zabbix_agent.sh --test
```

## 📋 Параметры скрипта

```bash
./install_zabbix_agent.sh [SERVER_IP] [HOSTNAME] [OPTIONS]
```

**Параметры:**
- `SERVER_IP` - IP адрес Zabbix Server (по умолчанию: 127.0.0.1)
- `HOSTNAME` - имя хоста для идентификации (по умолчанию: текущее имя хоста)

**Опции:**
- `--test` - тестовый режим без установки
- `--help` - показать справку

## 🔧 Что делает скрипт

1. **Автоопределение ОС** - определяет дистрибутив и версию
2. **Установка репозитория** - добавляет официальный репозиторий Zabbix
3. **Установка пакетов** - устанавливает Zabbix Agent 6.4
4. **Конфигурация** - настраивает подключение к серверу
5. **Безопасность** - настраивает firewall и права доступа
6. **Автозапуск** - добавляет службу в автозагрузку

## 🛡️ Настройки безопасности

Скрипт автоматически применяет следующие настройки безопасности:

- Отключение удаленных команд (`EnableRemoteCommands=0`)
- Логирование команд (`LogRemoteCommands=1`)
- Настройка firewall правил
- Ограничение доступа только к указанному серверу

## 📊 Примеры использования

### Для production среды

```bash
# Установка для production сервера
sudo ./install_zabbix_agent.sh 10.0.1.100 prod-web-01

# Проверка статуса
sudo systemctl status zabbix-agent
```

### Для тестирования

```bash
# Тестовый запуск
./install_zabbix_agent.sh --test

# Установка на localhost для тестирования
sudo ./install_zabbix_agent.sh 127.0.0.1 test-host
```

## 🔍 Проверка работы

После установки проверьте статус агента:

```bash
# Статус службы
sudo systemctl status zabbix-agent

# Просмотр логов
sudo tail -f /var/log/zabbix/zabbix_agentd.log

# Проверка конфигурации
sudo cat /etc/zabbix/zabbix_agentd.conf | grep -E "Server|Hostname"

# Тест подключения к серверу
sudo zabbix_agentd -t agent.ping
```

## 🐛 Устранение неполадок

### Агент не подключается к серверу

```bash
# Проверить сетевое подключение
telnet YOUR_ZABBIX_SERVER 10051

# Проверить firewall
sudo ufw status  # Ubuntu/Debian
sudo firewall-cmd --list-all  # CentOS/RHEL
```

### Служба не запускается

```bash
# Проверить синтаксис конфигурации
sudo zabbix_agentd -t

# Проверить права доступа
sudo ls -la /etc/zabbix/zabbix_agentd.conf
```

## 📁 Файлы проекта

- `install_zabbix_agent.sh` - основной скрипт установки
- `fix_zabbix_server.sh` - скрипт настройки Zabbix Server  
- `test_zabbix_agent.sh` - тестовый скрипт
- `README.md` - эта документация

## 🤝 Вклад в проект

Приветствуются любые улучшения! Пожалуйста:

1. Создайте Fork репозитория
2. Создайте ветку для изменений (`git checkout -b feature/improvement`)
3. Сделайте Commit (`git commit -am 'Add some improvement'`)
4. Push в ветку (`git push origin feature/improvement`)
5. Создайте Pull Request

## 📜 Лицензия

Проект распространяется под лицензией MIT. См. файл [LICENSE](LICENSE) для подробностей.

## 🔗 Полезные ссылки

- [Официальная документация Zabbix](https://www.zabbix.com/documentation/current/)
- [Zabbix Agent конфигурация](https://www.zabbix.com/documentation/current/en/manual/appendix/config/zabbix_agentd)
- [Репозитории Zabbix](https://repo.zabbix.com/)

---

**Автор:** [Kruiser1917](https://github.com/Kruiser1917)  
**Дата создания:** Январь 2025 