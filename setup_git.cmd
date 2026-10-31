@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

title Первичная настройка Git и привязка к GitHub

echo ========================================================
echo       ПЕРВИЧНАЯ НАСТРОЙКА GIT И ПРИВЯЗКА К АККАУНТУ
echo ========================================================
echo.

:: ==========================================================
:: 1. ПРОВЕРКА НАЛИЧИЯ И УСТАНОВКА GIT
:: ==========================================================
echo [1/3] Проверка наличия Git...

where git >nul 2>&1
if %ERRORLEVEL% equ 0 goto git_found

if exist "%ProgramFiles%\Git\cmd\git.exe" goto add_path_pf
if exist "%ProgramFiles(x86)%\Git\cmd\git.exe" goto add_path_pfx86
if exist "%LocalAppData%\Programs\Git\cmd\git.exe" goto add_path_local

echo [!] Git не обнаружен в системе. Начинаем автоматическую установку...

where winget >nul 2>&1
if %ERRORLEVEL% neq 0 goto download_git_curl

echo [Установка] Установка Git через Windows Package Manager (winget)...
winget install --id Git.Git -e --source winget --accept-source-agreements --accept-package-agreements
if %ERRORLEVEL% equ 0 goto refresh_path

echo [Предупреждение] Установка через winget не удалась. Скачиваем официальный установщик...

:download_git_curl
echo [Установка] Скачивание официального установщика Git for Windows...
set "GIT_INSTALLER=%TEMP%\Git-64-bit-installer.exe"
curl.exe -L -f -o "!GIT_INSTALLER!" "https://github.com/git-for-windows/git/releases/latest/download/Git-64-bit.exe"
if %ERRORLEVEL% neq 0 goto download_failed

echo [Установка] Запуск тихой установки Git в фоновом режиме...
"!GIT_INSTALLER!" /VERYSILENT /NORESTART /NOCANCEL /SP- /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS
set "INSTALL_STATUS=%ERRORLEVEL%"
if exist "!GIT_INSTALLER!" del /f /q "!GIT_INSTALLER!"

if %INSTALL_STATUS% neq 0 goto install_failed
goto refresh_path

:download_failed
echo [ОШИБКА] Не удалось скачать Git. Проверьте интернет-соединение.
pause
exit /b 1

:install_failed
echo [ОШИБКА] Установка завершилась с ошибкой: %INSTALL_STATUS%
pause
exit /b 1

:add_path_pf
set "PATH=%ProgramFiles%\Git\cmd;!PATH!"
goto git_found

:add_path_pfx86
set "PATH=%ProgramFiles(x86)%\Git\cmd;!PATH!"
goto git_found

:add_path_local
set "PATH=%LocalAppData%\Programs\Git\cmd;!PATH!"
goto git_found

:refresh_path
if exist "%ProgramFiles%\Git\cmd\git.exe" set "PATH=%ProgramFiles%\Git\cmd;!PATH!"
if exist "%ProgramFiles(x86)%\Git\cmd\git.exe" set "PATH=%ProgramFiles(x86)%\Git\cmd;!PATH!"
if exist "%LocalAppData%\Programs\Git\cmd\git.exe" set "PATH=%LocalAppData%\Programs\Git\cmd;!PATH!"

where git >nul 2>&1
if %ERRORLEVEL% equ 0 goto git_found

echo [Внимание] Git установлен. Пожалуйста, перезапустите этот скрипт.
pause
exit /b 0

:git_found
for /f "tokens=*" %%v in ('git --version 2^>nul') do set "GIT_VERSION=%%v"
echo [OK] !GIT_VERSION! готов к работе.
echo.

:: ==========================================================
:: 2. НАСТРОЙКА ИМЕНИ И EMAIL ПОЛЬЗОВАТЕЛЯ
:: ==========================================================
echo [2/3] Настройка имени и email (для подписи коммитов)...
echo.

set "CURR_NAME="
set "CURR_EMAIL="
for /f "tokens=*" %%a in ('git config --global user.name 2^>nul') do set "CURR_NAME=%%a"
for /f "tokens=*" %%a in ('git config --global user.email 2^>nul') do set "CURR_EMAIL=%%a"

:ask_name
if defined CURR_NAME goto has_name

set "USER_NAME="
set /p "USER_NAME=Введите ваше имя и фамилию (например, Ivan Ivanov): "
if not defined USER_NAME goto ask_name_retry
goto ask_email

:ask_name_retry
echo [!] Имя не может быть пустым.
goto ask_name

:has_name
echo Текущее имя: !CURR_NAME!
set "USER_NAME="
set /p "USER_NAME=Введите новое имя (или нажмите Enter, чтобы оставить [!CURR_NAME!]): "
if not defined USER_NAME set "USER_NAME=!CURR_NAME!"

:ask_email
if defined CURR_EMAIL goto has_email

set "USER_EMAIL="
set /p "USER_EMAIL=Введите ваш email (например, user@example.com): "
if not defined USER_EMAIL goto ask_email_retry
goto save_identity

:ask_email_retry
echo [!] Email не может быть пустым.
goto ask_email

:has_email
echo Текущий email: !CURR_EMAIL!
set "USER_EMAIL="
set /p "USER_EMAIL=Введите новый email (или нажмите Enter, чтобы оставить [!CURR_EMAIL!]): "
if not defined USER_EMAIL set "USER_EMAIL=!CURR_EMAIL!"

:save_identity
echo.
echo Сохранение настроек пользователя...
git config --global user.name "!USER_NAME!"
git config --global user.email "!USER_EMAIL!"

:: Базовые настройки Git
git config --global init.defaultBranch main
git config --global core.autocrlf true
git config --global core.quotepath false
git config --global credential.helper manager
git config --global pull.rebase false

echo [OK] Базовые параметры применены:
echo   - Главная ветка: main
echo   - Переводы строк Windows: core.autocrlf = true
echo   - Поддержка кириллицы в путях: core.quotepath = false
echo   - Диспетчер паролей Windows: credential.helper = manager
echo   - Безопасное слияние: pull.rebase = false
echo.

:: ==========================================================
:: 3. ВХОД В GITHUB ЧЕРЕЗ БРАУЗЕР (В ОДИН КЛИК)
:: ==========================================================
echo [3/3] Настройка входа в GitHub через браузер...
echo.

where gh >nul 2>&1
if %ERRORLEVEL% equ 0 goto check_gh_auth

where winget >nul 2>&1
if %ERRORLEVEL% neq 0 goto gcm_fallback

echo [Установка] GitHub CLI не найден. Устанавливаем через winget для входа в 1 клик...
winget install --id GitHub.cli -e --source winget --accept-source-agreements --accept-package-agreements
if exist "%ProgramFiles%\GitHub CLI\gh.exe" set "PATH=%ProgramFiles%\GitHub CLI;!PATH!"
if exist "%LocalAppData%\Programs\GitHub CLI\gh.exe" set "PATH=%LocalAppData%\Programs\GitHub CLI;!PATH!"

where gh >nul 2>&1
if %ERRORLEVEL% neq 0 goto gcm_fallback

:check_gh_auth
gh auth status >nul 2>&1
if %ERRORLEVEL% neq 0 goto prompt_gh_login

set "GH_USER="
for /f "tokens=*" %%u in ('gh api user --jq .login 2^>nul') do set "GH_USER=%%u"
if not defined GH_USER set "GH_USER=подключен"

echo [OK] Вы уже успешно авторизованы в GitHub: !GH_USER!
echo.
set "REAUTH=N"
set /p "REAUTH=Хотите сменить аккаунт или переавторизоваться? [Y/N, по умолчанию N]: "
if /i "!REAUTH!"=="Y" goto do_gh_login
if /i "!REAUTH!"=="YES" goto do_gh_login
if /i "!REAUTH!"=="Д" goto do_gh_login
if /i "!REAUTH!"=="ДА" goto do_gh_login
gh auth setup-git
goto finish_step

:prompt_gh_login
echo.
echo Для привязки к GitHub сейчас откроется браузер.
echo Потребуется подтвердить код и нажать кнопку Authorize.
echo.
set "DO_LOGIN=Y"
set /p "DO_LOGIN=Открыть браузер и войти в GitHub прямо сейчас? [Y/N, по умолчанию Y]: "
if /i "!DO_LOGIN!"=="N" goto gcm_fallback
if /i "!DO_LOGIN!"=="NO" goto gcm_fallback
if /i "!DO_LOGIN!"=="Н" goto gcm_fallback
if /i "!DO_LOGIN!"=="НЕТ" goto gcm_fallback

:do_gh_login
echo.
echo Запуск авторизации через браузер...
gh auth login --web -h github.com -p https
gh auth setup-git
goto finish_step

:gcm_fallback
echo.
echo [Инфо] Диспетчер учетных данных Windows (Git Credential Manager) настроен.
echo Браузер автоматически откроется для входа в GitHub при первой отправке кода (git push).

:: ==========================================================
:: ФИНАЛ: ВЫВОД ИТОГОВОЙ КОНФИГУРАЦИИ
:: ==========================================================
:finish_step
echo.
echo ========================================================
echo            ИТОГОВАЯ КОНФИГУРАЦИЯ GIT
echo ========================================================
git config --global --list
echo ========================================================
echo.
echo [ГОТОВО] Первичная настройка компьютера завершена!
echo.
pause
