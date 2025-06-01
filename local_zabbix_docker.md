# 🐳 Быстрый запуск Zabbix в Docker

## 🚀 Локальный тест Zabbix за 5 минут

Если на удаленном сервере нет веб-интерфейса, можно быстро поднять локальный Zabbix для тестирования.

### 1. Установить Docker Desktop (если нет)
- Скачать: https://docker.com/products/docker-desktop
- Установить и запустить

### 2. Создать docker-compose.yml

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:13
    environment:
      POSTGRES_DB: zabbix
      POSTGRES_USER: zabbix
      POSTGRES_PASSWORD: zabbix_pass
    volumes:
      - postgres_data:/var/lib/postgresql/data

  zabbix-server:
    image: zabbix/zabbix-server-pgsql:6.4-latest
    environment:
      DB_SERVER_HOST: postgres
      POSTGRES_DB: zabbix
      POSTGRES_USER: zabbix
      POSTGRES_PASSWORD: zabbix_pass
    depends_on:
      - postgres
    ports:
      - "10051:10051"

  zabbix-web:
    image: zabbix/zabbix-web-nginx-pgsql:6.4-latest
    environment:
      ZBX_SERVER_HOST: zabbix-server
      DB_SERVER_HOST: postgres
      POSTGRES_DB: zabbix
      POSTGRES_USER: zabbix
      POSTGRES_PASSWORD: zabbix_pass
    depends_on:
      - postgres
      - zabbix-server
    ports:
      - "8080:8080"

volumes:
  postgres_data:
```

### 3. Запустить

```bash
# В PowerShell
docker-compose up -d

# Проверить статус
docker-compose ps
```

### 4. Открыть веб-интерфейс
- URL: http://localhost:8080
- Логин: Admin
- Пароль: zabbix

### 5. Переконфигурировать агент

```bash
# В WSL
wsl sudo ./install_zabbix_agent.sh localhost ubuntu-wsl-rafael
```

## ✅ Преимущества локального тестирования:
- ✅ Полный контроль
- ✅ Быстрая настройка  
- ✅ Можно экспериментировать
- ✅ Не зависит от внешнего сервера 