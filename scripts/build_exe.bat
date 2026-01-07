@echo off
REM Build script for PredictBanHelper (Windows)
REM Run from Explorer or CMD. This script will install build deps and run PyInstaller.

cd /d %~dp0
python -m pip install --upgrade pip
python -m pip install -r requirements-build.txt

pyinstaller --noconfirm --onefile --windowed --name PredictBanHelper predict_ui.py

if exist dist\PredictBanHelper.exe (
  echo Build succeeded: dist\PredictBanHelper.exe
) else (
  echo Build finished. Check PyInstaller output for errors.
)

pause
