#!/bin/bash

# ==============================================
# Скрипт синхронизации Git-репозиториев (Bash)
# ==============================================

# ----------- НАСТРОЙКИ (ИЗМЕНИТЕ ПУТИ!) -----------
# Исходный репозиторий (из него будем делать pull и копировать)
SOURCE_REPO="/home/user/projects/my-project-source"

# Целевой репозиторий (в него будем копировать файлы, заменяя существующие)
TARGET_REPO="/home/user/projects/my-project-target"
# -------------------------------------------------

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Функция для проверки существования папки
check_directory() {
    local dir=$1
    local name=$2
    if [ ! -d "$dir" ]; then
        echo -e "${RED}Ошибка: Директория '$dir' ($name) не существует.${NC}"
        exit 1
    else
        echo -e "${GREEN}Директория $name найдена: $dir${NC}"
    fi
}

# Функция для выполнения git pull
git_pull_repo() {
    local repo_path=$1
    echo -e "${YELLOW}Переход в директорию: $repo_path${NC}"
    cd "$repo_path" || exit 1

    echo -e "${YELLOW}Выполнение 'git pull'...${NC}"
    if git pull; then
        echo -e "${GREEN}Git pull выполнен успешно.${NC}"
    else
        echo -e "${RED}Ошибка при выполнении git pull. Проверьте доступ к интернету и права репозитория.${NC}"
        exit 1
    fi
}

# Функция для синхронизации (копирования) папок
sync_directories() {
    local source=$1
    local target=$2

    echo -e "${YELLOW}Синхронизация: $source -> $target${NC}"

    # Используем rsync для копирования:
    # -a : архивный режим (сохраняет права, ссылки и т.д., рекурсивно)
    # -v : подробный вывод (verbose)
    # --delete : удалять файлы в target, которых нет в source (опционально, для полной синхронизации)
    # --exclude=.git : исключаем папку .git из копирования
    # --progress : показывать прогресс по каждому файлу

    # Важно: добавляем слеш в конце source/, чтобы копировалось СОДЕРЖИМОЕ папки, а не сама папка.
    rsync -av --delete --exclude='.git' --progress "$source/" "$target/"

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Синхронизация завершена успешно.${NC}"
    else
        echo -e "${RED}Ошибка во время синхронизации.${NC}"
        exit 1
    fi
}

# ========== ОСНОВНАЯ ЛОГИКА ==========
echo -e "${GREEN}=== Запуск скрипта синхронизации репозиториев (Bash) ===${NC}"

# 1. Проверяем существование папок
check_directory "$SOURCE_REPO" "Исходный репозиторий (SOURCE)"
check_directory "$TARGET_REPO" "Целевой репозиторий (TARGET)"

# 2. Обновляем исходный репозиторий через git pull
git_pull_repo "$SOURCE_REPO"

# 3. Синхронизируем содержимое исходного репозитория (кроме .git) с целевым
sync_directories "$SOURCE_REPO" "$TARGET_REPO"

echo -e "${GREEN}=== Скрипт успешно завершен ===${NC}"
exit 0