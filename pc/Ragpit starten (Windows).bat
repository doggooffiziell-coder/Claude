@echo off
rem Startet Ragpit in einem eigenen Fenster ohne Adressleiste.
rem Gibt es weder Edge noch Chrome, oeffnet der normale Browser das Spiel.
set "GAME=%~dp0Ragpit.html"
set "URL=file:///%GAME:\=/%"
set "PROFILE=%LOCALAPPDATA%\Ragpit\browser"
for %%B in (
  "%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe"
  "%ProgramFiles%\Microsoft\Edge\Application\msedge.exe"
  "%ProgramFiles%\Google\Chrome\Application\chrome.exe"
  "%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe"
  "%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe"
) do (
  if exist %%B (
    start "" %%B --app="%URL%" --start-fullscreen --user-data-dir="%PROFILE%" --autoplay-policy=no-user-gesture-required
    exit /b
  )
)
start "" "%GAME%"
