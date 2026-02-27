<#
СКРИПТ СИНХРОНИЗАЦИИ РЕПОЗИТОРИЕВ
Настроен специально для: artem
#>

# ========== НАСТРОЙКИ (УЖЕ ИЗМЕНЕНЫ ПОД ВАС) ==========
$SOURCE_REPO = "C:\Users\artem\source-repo"     # ВАШ основной репозиторий
$TARGET_REPO = "C:\Users\artem\target-repo"     # Папка для синхронизации (будет создана)
# ======================================================

# Очищаем экран
Clear-Host

# Заголовок
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "    СКРИПТ СИНХРОНИЗАЦИИ РЕПОЗИТОРИЕВ" -ForegroundColor Cyan
Write-Host "    Пользователь: artem" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

# Функция проверки пути
function Test-FolderPath {
    param($Path, $Name)
    
    if (Test-Path $Path) {
        Write-Host "✅ $Name: $Path" -ForegroundColor Green
        return $true
    } else {
        Write-Host "❌ $Name: $Path НЕ НАЙДЕН!" -ForegroundColor Red
        return $false
    }
}

# Функция проверки Git
function Test-Git {
    try {
        $git = Get-Command git -ErrorAction Stop
        Write-Host "✅ Git найден: $($git.Version)" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "❌ Git НЕ УСТАНОВЛЕН!" -ForegroundColor Red
        Write-Host "   Скачайте с: https://git-scm.com/download/win" -ForegroundColor Yellow
        return $false
    }
}

# Функция создания папки если её нет
function Ensure-Folder {
    param($Path)
    
    if (-not (Test-Path $Path)) {
        Write-Host "📁 Создаю папку: $Path" -ForegroundColor Yellow
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

# Функция для проверки содержимого папки
function Show-FolderContent {
    param($Path)
    
    if (Test-Path $Path) {
        $items = Get-ChildItem -Path $Path
        Write-Host "   Содержит $($items.Count) элементов" -ForegroundColor Gray
    }
}

# Главная функция
function Sync-Repositories {
    Write-Host "`n🚀 Начинаем синхронизацию..." -ForegroundColor Magenta
    Write-Host "------------------------------------"
    
    # Шаг 1: Проверяем Git
    if (-not (Test-Git)) {
        Read-Host "`nНажмите Enter для выхода"
        exit 1
    }
    
    # Шаг 2: Проверяем исходную папку
    Write-Host "`n📂 Проверка папок:" -ForegroundColor Yellow
    $sourceOk = Test-FolderPath $SOURCE_REPO "Исходный репозиторий"
    
    if (-not $sourceOk) {
        Write-Host "`n❌ Исходный репозиторий не найден!" -ForegroundColor Red
        Write-Host "Создаю папку $SOURCE_REPO..." -ForegroundColor Yellow
        Ensure-Folder $SOURCE_REPO
        Write-Host "✅ Папка создана" -ForegroundColor Green
        Write-Host "⚠️  Но репозиторий пуст. Склонируйте в неё проект:" -ForegroundColor Yellow
        Write-Host "   cd $SOURCE_REPO" -ForegroundColor White
        Write-Host "   git clone <ссылка-на-репозиторий> ." -ForegroundColor White
        Read-Host "`nНажмите Enter для выхода"
        exit 1
    }
    
    # Показываем содержимое исходной папки
    Show-FolderContent $SOURCE_REPO
    
    # Шаг 3: Проверяем/создаем целевую папку
    Test-FolderPath $TARGET_REPO "Целевой репозиторий"
    Ensure-Folder $TARGET_REPO
    
    # Шаг 4: Сохраняем текущую папку
    $currentDir = Get-Location
    
    # Шаг 5: Git pull в исходном репозитории
    Write-Host "`n🔄 Обновление исходного репозитория..." -ForegroundColor Yellow
    Write-Host "Папка: $SOURCE_REPO" -ForegroundColor Gray
    
    try {
        Set-Location $SOURCE_REPO -ErrorAction Stop
        
        # Проверяем, является ли папка Git-репозиторием
        $isGitRepo = Test-Path ".git"
        if (-not $isGitRepo) {
            Write-Host "⚠️  Папка не является Git-репозиторием (.git не найден)" -ForegroundColor Yellow
            Write-Host "   Пропускаю git pull" -ForegroundColor Yellow
        } else {
            Write-Host "Выполняю: git pull" -ForegroundColor Cyan
            $pullResult = git pull 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Git pull выполнен успешно!" -ForegroundColor Green
                if ($pullResult -match "Already up to date") {
                    Write-Host "   Репозиторий уже актуален" -ForegroundColor Yellow
                }
            } else {
                Write-Host "❌ Ошибка git pull:" -ForegroundColor Red
                Write-Host $pullResult -ForegroundColor Red
                Write-Host "`n💡 Проверьте:" -ForegroundColor Yellow
                Write-Host "   1. Интернет соединение" -ForegroundColor Yellow
                Write-Host "   2. Git remote настроен (git remote -v)" -ForegroundColor Yellow
                Write-Host "   3. Права доступа к репозиторию" -ForegroundColor Yellow
            }
        }
    } catch {
        Write-Host "❌ Ошибка при переходе в папку: $_" -ForegroundColor Red
    }
    
    # Шаг 6: Копирование файлов
    Write-Host "`n📋 Копирование файлов в целевой репозиторий..." -ForegroundColor Yellow
    
    try {
        # Получаем все файлы и папки из source, исключая .git
        Write-Host "Сканирование файлов..." -ForegroundColor Cyan
        
        $itemsToCopy = Get-ChildItem -Path $SOURCE_REPO -Exclude ".git"
        $totalItems = ($itemsToCopy | Measure-Object).Count
        
        Write-Host "Найдено элементов для копирования: $totalItems" -ForegroundColor Cyan
        
        if ($totalItems -eq 0) {
            Write-Host "⚠️  Исходная папка пуста (кроме возможной папки .git)" -ForegroundColor Yellow
        } else {
            Write-Host ""
            
            $copiedCount = 0
            $folderCount = 0
            
            # Копируем каждый элемент
            foreach ($item in $itemsToCopy) {
                $destPath = Join-Path $TARGET_REPO $item.Name
                
                if ($item.PSIsContainer) {
                    # Это папка - копируем рекурсивно
                    Write-Host "   📁 Папка: $($item.Name)" -ForegroundColor Gray
                    Copy-Item -Path $item.FullName -Destination $destPath -Recurse -Force
                    $folderCount++
                } else {
                    # Это файл
                    Write-Host "   📄 Файл: $($item.Name)" -ForegroundColor Gray
                    Copy-Item -Path $item.FullName -Destination $destPath -Force
                    $copiedCount++
                }
            }
            
            Write-Host ""
            Write-Host "✅ Копирование завершено!" -ForegroundColor Green
            Write-Host "   Скопировано папок: $folderCount" -ForegroundColor Green
            Write-Host "   Скопировано файлов: $copiedCount" -ForegroundColor Green
        }
        
    } catch {
        Write-Host "❌ Ошибка при копировании: $_" -ForegroundColor Red
    }
    
    # Возвращаемся в исходную папку
    Set-Location $currentDir
    
    # Шаг 7: ИТОГ
    Write-Host "`n==============================================" -ForegroundColor Cyan
    Write-Host "✅ СИНХРОНИЗАЦИЯ ЗАВЕРШЕНА!" -ForegroundColor Green
    Write-Host "==============================================" -ForegroundColor Cyan
    Write-Host "Исходный репозиторий: $SOURCE_REPO" -ForegroundColor White
    Write-Host "Целевой репозиторий : $TARGET_REPO" -ForegroundColor White
    
    # Показываем содержимое целевой папки
    if (Test-Path $TARGET_REPO) {
        $targetItems = Get-ChildItem -Path $TARGET_REPO
        Write-Host "Целевая папка содержит: $($targetItems.Count) элементов" -ForegroundColor Gray
    }
    
    Write-Host "Время: $(Get-Date -Format 'HH:mm:ss dd.MM.yyyy')" -ForegroundColor White
}

# Запуск
Sync-Repositories

# Пауза
Write-Host "`n"
Read-Host "Нажмите Enter для выхода"