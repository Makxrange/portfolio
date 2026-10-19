#!/bin/bash

echo " Начинаем обновление приложения..."

# Скачиваем новые образы
echo " Скачиваем последние версии..."
docker compose pull

# Пересоздаем контейнеры с флагом --force-recreate
echo " Пересоздаем сервисы..."
docker compose up -d --force-recreate

# Очищаем старые образы
echo " Очищаем мусор..."
docker image prune -f

echo " Деплой завершен!"