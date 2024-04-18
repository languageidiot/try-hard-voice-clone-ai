@echo off
SETLOCAL EnableDelayedExpansion

REM Environment Variables winget
set "winget_path=%userprofile%\AppData\Local\Microsoft\WindowsApps"

REM Check if Winget is installed; if not, then install it
winget --version > nul 2>&1
if %errorlevel% neq 0 (
    echo  [WARN] Winget is not installed on this system.
    echo  [INFO] Installing Winget...
    curl -L -o "%temp%\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle" "https://github.com/microsoft/winget-cli/releases/download/v1.6.2771/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
    start "" "%temp%\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
    echo  [INFO] Winget installed successfully.
) else (
    echo [INFO] Winget is already installed.
)

REM Check and install Python
python --version > NUL 2>&1
if %errorlevel% NEQ 0 (
    echo Installing Python 3.10.6...
    powershell -Command "& {Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/3.10.6/python-3.10.6-amd64.exe' -OutFile 'python-3.10.6-amd64.exe'}"
    if %errorlevel% NEQ 0 (
        echo Failed to download Python installer.
        exit /b
    )
    start /wait python-3.10.6-amd64.exe /quiet InstallAllUsers=1 PrependPath=1
    del python-3.10.6-amd64.exe
) else (
    echo Python already installed.
)

REM Check and install Git
git --version > NUL 2>&1
if %errorlevel% NEQ 0 (
    echo Installing Git...
    powershell -Command "& {Invoke-WebRequest -Uri 'https://github.com/git-for-windows/git/releases/download/v2.41.0.windows.3/Git-2.41.0.3-64-bit.exe' -OutFile 'Git-2.41.0.3-64-bit.exe'}"
    if %errorlevel% NEQ 0 (
        echo Failed to download Git installer.
        exit /b
    )
    start /wait Git-2.41.0.3-64-bit.exe /VERYSILENT
    del Git-2.41.0.3-64-bit.exe
) else (
    echo Git already installed.
)

REM Install Microsoft.VCRedistif 32bit - 64bit & BuildTools
echo  [INFO] Installing Microsoft.VCRedist.2015+.x64...
winget install -e --id Microsoft.VCRedist.2015+.x64

echo  [INFO] Installing Microsoft.VCRedist.2015+.x86...
winget install -e --id Microsoft.VCRedist.2015+.x86

echo  [INFO] Installing vs_BuildTools...
curl -L -o "%temp%\vs_buildtools.exe" "https://aka.ms/vs/17/release/vs_BuildTools.exe"

if %errorlevel% neq 0 (
  echo  [ERROR] Download failed. Please restart the installer
  pause
) else (
  start "" "%temp%\vs_buildtools.exe" --norestart --passive --downloadThenInstall --includeRecommended --add Microsoft.VisualStudio.Workload.NativeDesktop --add Microsoft.VisualStudio.Workload.VCTools --add Microsoft.VisualStudio.Workload.MSBuildTools
)


REM Cloning the RVC repository
git clone https://github.com/RVC-Project/Retrieval-based-Voice-Conversion-WebUI.git
cd Retrieval-based-Voice-Conversion-WebUI

REM Setting up a Python virtual environment
python -m venv env
CALL env\Scripts\activate

REM Install PyTorch with the detected CUDA version
pip install torch torchvision torchaudio

REM Installing other Python requirements
pip install -r requirements-dml.txt

pip uninstall numpy -y
pip install numpy==1.23.5

pip install -r requirements-win-for-realtime_vc_gui-dml.txt 

python -m pip install pysimplegui

REM Downloading models from Hugging Face
echo Downloading models...
python tools/download_models.py

REM Downloading FFmpeg and .bat files
echo Downloading FFmpeg and additional .bat files...
curl -L https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/ffmpeg.exe?download=true -o ffmpeg.exe
curl -L https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/ffprobe.exe?download=true -o ffprobe.exe
curl -L https://huggingface.co/Aitrepreneur/test/resolve/main/go-web.bat?download=true -o go-web.bat
curl -L https://huggingface.co/Aitrepreneur/test/resolve/main/go-web-dml.bat?download=true -o go-web-dml.bat
curl -L https://huggingface.co/Aitrepreneur/test/resolve/main/go-realtime-gui.bat?download=true -o go-realtime-gui.bat
curl -L https://huggingface.co/Aitrepreneur/test/resolve/main/go-realtime-gui-dml.bat?download=true -o go-realtime-gui-dml.bat

echo Installation complete. Starting RVC WebUI...
python infer-web.py --port 7897 --dml