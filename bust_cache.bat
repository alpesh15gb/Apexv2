@echo off
setlocal

set BUILD_DIR=%~dp0frontend\build\web
set TIMESTAMP=%date:~10,4%%date:~4,2%%date:~7,2%%time:~0,2%%time:~3,2%%time:~6,2%
set TIMESTAMP=%TIMESTAMP: =0%

echo Adding cache-busting v=%TIMESTAMP% to index.html...

powershell -Command "(Get-Content '%BUILD_DIR%\index.html') -replace 'main\.dart\.js', 'main.dart.js?v=%TIMESTAMP%' -replace 'flutter_bootstrap\.js', 'flutter_bootstrap.js?v=%TIMESTAMP%' -replace 'flutter\.js''', 'flutter.js?v=%TIMESTAMP%''' | Set-Content '%BUILD_DIR%\index.html'"

echo Done. Deploy the build/web folder to the server.
