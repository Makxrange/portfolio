# DevOps Pet Project: Автоматизация развертывания веб-приложения

## Что это за проект?

Это учебный проект, в котором я реализовал полный цикл разработки и доставки веб-приложения — от написания кода до автоматического деплоя. Проект демонстрирует базовые навыки DevOps-инженера: контейнеризацию, оркестрацию, CI/CD и работу с инфраструктурой как кодом.

---

## Как это работает? (Простыми словами)

Представь, что ты разработчик, который написал новое приложение. Раньше, чтобы запустить его на сервере, нужно было:
1. Зайти на сервер по SSH.
2. Вручную установить Python, зависимости, Nginx.
3. Скопировать код.
4. Запустить приложение.
5. Если что-то сломалось — повторить всё заново.

- **Проблема:** Это долго, делается вручную, и на разных серверах может работать по-разному ("у меня на компьютере работало!").
- **Решение:** Упаковать всё в **Docker-контейнер** (как в герметичную коробку, где есть всё необходимое) и настроить **автоматическую доставку** через CI/CD.

---

## Структура проекта

```text
portfolio/
├── app.py                      # Наше веб-приложение на Python (Flask)
├── requirements.txt            # Список Python-библиотек (зависимости)
├── Dockerfile                  # Инструкция: как упаковать приложение в Docker
├── docker-compose.yml          # Описание всей инфраструктуры (Nginx + App)
├── nginx.conf                  # Настройки Nginx (как перенаправлять запросы)
├── deploy.sh                   # Bash-скрипт автоматического обновления
└── .github/
    └── workflows/
        └── ci.yml              # Настройки GitHub Actions (робот для CI/CD)
```

---

##  Подробное описание компонентов

### 1. Приложение (app.py)
Простое веб-приложение на Python с использованием фреймворка Flask.
- Отвечает на запрос `GET /` текстом `"Hello from my Docker container!"`
- Отвечает на запрос `GET /health` текстом `"OK"` (для проверки работоспособности / health-check).

> **Важный момент:** Приложение слушает `0.0.0.0:5000`, а не `127.0.0.1:5000`. Это критически важно для Docker, так как `127.0.0.1` внутри контейнера означает "только сам контейнер", и хост-машина не сможет к нему подключиться.

### 2. Dockerfile
Инструкция для сборки Docker-образа.

```dockerfile
FROM python:3.11-slim
# Берем легкий базовый образ. Меньше размер = меньше поверхность для атак (DevSecOps)

WORKDIR /app
# Создаем и переходим в рабочую директорию внутри контейнера

COPY requirements.txt .
# Копируем файл зависимостей

RUN pip install --no-cache-dir -r requirements.txt
# Устанавливаем библиотеки. Флаг --no-cache-dir экономит место в образе

COPY app.py .
# Копируем код приложения

EXPOSE 5000
# Документируем, что приложение использует порт 5000

CMD ["python", "app.py"]
# Команда, которая запустится при старте контейнера
```

### 3. Nginx (nginx.conf)
Веб-сервер, работающий как Reverse Proxy (обратный прокси).
- Принимает запросы на стандартном порту 80.
- Перенаправляет их на Flask-приложение (порт 5000).
- Скрывает реальную структуру приложения от внешнего мира.

```nginx
server {
    listen 80;

    location / {
        proxy_pass http://app:5000;  # Перенаправляем на сервис "app" из docker-compose
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### 4. Docker Compose (docker-compose.yml)
Описывает всю инфраструктуру для запуска одной командой.

```yaml
services:
  app:
    image: mylesgwy/portfolio-app:latest  # Образ из Docker Hub
    build: .                              # Или собрать локально из Dockerfile
    expose:
      - "5000"                            # Порт доступен ТОЛЬКО внутри сети Docker

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"                           # Пробрасываем порт 80 на хост-машину
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro # :ro = read-only (защита от изменений)
    depends_on:
      - app                               # Ждем запуска app перед стартом nginx
```

### 5. GitHub Actions (.github/workflows/ci.yml)
Автоматизированный пайплайн, который запускается при каждом `git push`.

```yaml
on:
  push:
    branches: [ main ]

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Log in to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      - name: Build and push Docker image
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ${{ secrets.DOCKER_USERNAME }}/portfolio-app:latest
```

### 6. Скрипт деплоя (deploy.sh)
Bash-скрипт для обновления приложения на сервере.

```bash
#!/bin/bash
docker compose pull                   # Скачивает новые образы
docker compose up -d --force-recreate # Пересоздает контейнеры
docker image prune -f                 # Очищает старые образы, экономя место
```

---

##  CI/CD Pipeline: Пошаговый процесс

1. **Разработка:** Я вношу изменения в код (например, меняю текст приветствия).
2. **Коммит и пуш:** `git add .`, `git commit -m "update"`, `git push`.
3. **CI (Continuous Integration):** GitHub Actions автоматически скачивает код, логинится в Docker Hub (через Secrets), собирает новый образ и отправляет его в облако.
4. **CD (Continuous Deployment):** На сервере я запускаю `./deploy.sh`, который скачивает свежий образ и перезапускает контейнеры.
5. **Проверка:** Открываю браузер и вижу обновленное приложение!

---

## 🎯Чему я научился

- **Docker:** Контейнеризация, написание оптимальных Dockerfile.
- **Docker Compose:** Оркестрация многоконтейнерных приложений, управление сетями.
- **Nginx:** Настройка Reverse Proxy.
- **CI/CD:** Построение автоматизированных пайплайнов с GitHub Actions.
- **Git:** Работа с системой контроля версий.
- **Bash:** Написание скриптов для автоматизации рутинных задач.
- **DevSecOps:** Применение принципов наименьших привилегий (expose вместо ports, read-only volumes, минимальные базовые образы).

---

##  Полезные команды

```bash
# Сборка и запуск
docker compose up -d --build

# Остановка и удаление контейнеров
docker compose down

# Просмотр логов в реальном времени
docker compose logs -f

# Обновление образов из реестра
docker compose pull

# Принудительное пересоздание контейнеров
docker compose up -d --force-recreate

# Очистка неиспользуемых образов (освобождение места)
docker image prune -f

# Просмотр запущенных контейнеров
docker ps
```