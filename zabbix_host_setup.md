# 📋 Инструкция добавления хоста в Zabbix

## 🌐 Добавление Ubuntu WSL хоста в Zabbix

### 1. Войдите в веб-интерфейс
- URL: `http://185.219.81.180`
- Логин: Admin (или ваш логин)
- Пароль: [ваш пароль]

### 2. Перейдите к настройке хостов
```
Меню → Configuration → Hosts → Create host
```

### 3. Заполните основные данные хоста:

**Вкладка "Host":**
- **Host name:** `ubuntu-wsl-rafael`
- **Visible name:** `Ubuntu WSL Rafael (Windows 10)`
- **Groups:** `Linux servers` (выберите из списка)

**Interfaces:**
- **Type:** Agent
- **IP address:** `ВАШ_ВНЕШНИЙ_IP` или `127.0.0.1`
- **DNS name:** (оставить пустым)
- **Port:** `10050`

### 4. Добавьте шаблоны мониторинга

**Вкладка "Templates":**
- Нажмите **"Select"**
- Найдите и выберите: `Linux by Zabbix agent`
- Нажмите **"Add"**

### 5. Сохраните хост
- Нажмите **"Add"** внизу страницы

## ✅ Проверка подключения

### Через веб-интерфейс:
1. `Configuration → Hosts`
2. Найдите хост `ubuntu-wsl-rafael`
3. В колонке **Availability** должны загореться зеленые иконки:
   - **Z** (Zabbix agent) - зеленый
   - **S** (SNMP) - серый (не используется)
   - **I** (IPMI) - серый (не используется)

### Через командную строку:
```bash
# Проверить логи агента
sudo tail -f /var/log/zabbix/zabbix_agentd.log

# Должны появиться записи типа:
# "received configuration data from server at [185.219.81.180]"
```

## 🔍 Получение внешнего IP (если нужно)

Если Zabbix сервер не может подключиться к WSL по 127.0.0.1:

### Способ 1: Узнать IP WSL
```bash
wsl hostname -I
```

### Способ 2: Использовать Windows IP
```bash
ipconfig | findstr IPv4
```

### Способ 3: Настроить проброс портов Windows
```powershell
# Добавить правило переадресации (запустить от администратора)
netsh interface portproxy add v4tov4 listenport=10050 listenaddress=0.0.0.0 connectport=10050 connectaddress=172.x.x.x
```

## 📊 Что будет мониториться:

После подключения шаблона `Linux by Zabbix agent`:

### Системные метрики:
- **CPU:** загрузка процессора
- **Memory:** использование памяти
- **Disk:** свободное место на дисках
- **Network:** сетевая активность
- **Processes:** количество процессов

### Службы:
- **SSH:** доступность SSH
- **System:** время работы системы
- **Zabbix agent:** состояние самого агента

### Триггеры (предупреждения):
- Высокая загрузка CPU (>80%)
- Мало свободной памяти (<20%)
- Мало места на диске (<20%)
- Агент недоступен

## 🎯 Дополнительная настройка

### Добавить кастомные проверки:
```bash
# Создать пользовательский параметр
sudo nano /etc/zabbix/zabbix_agentd.conf

# Добавить строку:
UserParameter=custom.test,echo "Hello from Ubuntu WSL!"
```

### Перезапустить агент:
```bash
sudo systemctl restart zabbix-agent
```

### Тестировать локально:
```bash
zabbix_agentd -t custom.test
```

## 🚨 Устранение проблем

### Если хост не подключается:

1. **Проверить порты:**
```bash
sudo ss -tuln | grep 10050
```

2. **Проверить логи:**
```bash
sudo tail -f /var/log/zabbix/zabbix_agentd.log
```

3. **Проверить конфигурацию:**
```bash
sudo cat /etc/zabbix/zabbix_agentd.conf | grep -E "Server|Hostname"
```

4. **Проверить соединение с сервером:**
```bash
telnet 185.219.81.180 10051
```

### Типичные ошибки:
- **"host not found"** → хост не добавлен в веб-интерфейсе
- **"connection refused"** → проблемы с сетью/файрволом
- **"permission denied"** → проблемы с правами доступа

## 📈 Результат

После успешной настройки вы получите:
- ✅ Мониторинг Ubuntu WSL в реальном времени
- ✅ Графики производительности
- ✅ Уведомления о проблемах
- ✅ Исторические данные
- ✅ Возможность настройки собственных проверок

🎉 **Поздравляем! Ваш DevOps мониторинг готов!** 