@ECHO OFF
SETLOCAL
SETLOCAL EnableDelayedExpansion

set start_dir=%CD%

set cloneurl="https://github.com/senny/cabbage.git"
set conf_dir=%HOME%\.emacs.d


:: Test that GIT is installed
where git > NUL
if not  %ERRORLEVEL% == 0 (
  echo "git must be installed first."
  goto:finish
)


:: Determine where the checkout should happen
set /P root_dir="Where should cabbage store its files:"
if "%root_dir%" == "" (
   echo A path is required.
   goto:finish
)

set cabbage_dir=%root_dir%\cabbage
if not exist %root_dir% (
   mkdir %root_dir%
)


:: Backup the existing .emacs.d for safety
:backup
set date_str=%date:~4,2%%date:~7,2%%date:~10,4%_%time:~0,2%%time:~3,2%%time:~6,2%%
echo "%date_str%"
set backup=%conf_dir%.bak.%date_str%

if exist %conf_dir% (
   echo.
   echo Backing up existing emacs configuration to:
   echo "%backup%"
   xcopy /E /I "%conf_dir%" "%backup%" > NUL
)


:: Clone or update the repository
:repo
if not exist %cabbage_dir% (
   git clone %cloneurl% %cabbage_dir%
   cd %cabbage_dir%
   git submodule init
) else (
   cd %cabbage_dir%
   git pull --rebase
)

git submodule update


:: Move files to the correct spots
:config
echo. Removing old configuration files to
if exist %conf_dir% (
   rmdir /S %conf_dir%
)

echo. Moving new configuration to:
echo %conf_dir%
xcopy /E /I %cabbage_dir%\templates\emacs.d %conf_dir%
copy %cabbage_dir%\templates\init.el %conf_dir%\init.el

:: Customize the configuration for the users machine
set to_replace=CABBAGE-DIR
set replace_with=%cabbage_dir:\=/%

for /f "tokens=* delims= " %%a in (%conf_dir%\init.el) do (
  set str=%%a
  set str=!str:%to_replace%=%replace_with%!
  echo !str! >> %conf_dir%\init.el.tmp
)

move /Y %conf_dir%\init.el.tmp %conf_dir%\init.el > NUL


:finish
cd %start_dir%

ENDLOCAL

