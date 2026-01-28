#!/usr/bin/env bash
# setup_venv.sh — Cria o ambiente virtual Python e instala todas as dependências do projeto.

set -e
cd "$(dirname "$0")"
PROJECT_ROOT="$(pwd)"

echo "=============================================="
echo "  A.D.A V2 — Configuração do ambiente"
echo "=============================================="

# Em Linux, PyAudio precisa dos headers PortAudio
if [ "$(uname -s)" = "Linux" ]; then
  if ! pkg-config --exists portaudio 2>/dev/null && ! [ -f /usr/include/portaudio.h ]; then
    echo ""
    echo "  Aviso (Linux): Para o PyAudio funcionar, instale antes:"
    echo "    Debian/Ubuntu: sudo apt install portaudio19-dev"
    echo "    Fedora:        sudo dnf install portaudio-devel"
    echo "    Arch:          sudo pacman -S portaudio"
    echo ""
    echo "  Se pular isso, a instalação pode falhar em 'pyaudio'."
    echo ""
  fi
fi

# 1. Venv
if [ -d "venv" ]; then
  echo "[1/5] Ambiente virtual 'venv' já existe. Atualizando..."
else
  echo "[1/5] Criando ambiente virtual Python em venv/ ..."
  python3 -m venv venv
fi
source venv/bin/activate

# 2. Pip e requirements
echo "[2/5] Instalando dependências Python..."
pip install -q --upgrade pip
if ! pip install -r requirements.txt; then
  echo ""
  echo "  Erro ao instalar dependências. Em Linux, se o PyAudio falhou, instale:"
  echo "    sudo apt install portaudio19-dev   # Debian/Ubuntu"
  echo "  Depois rode este script novamente."
  exit 1
fi

# 3. Playwright
echo "[3/5] Instalando navegador Chromium (Playwright)..."
playwright install chromium

# 4. .env
if [ ! -f .env ]; then
  echo "[4/5] Criando .env a partir de .env.example ..."
  cp .env.example .env
  echo "      Edite o arquivo .env e adicione sua GEMINI_API_KEY."
else
  echo "[4/5] Arquivo .env já existe."
fi

# 5. npm
echo "[5/5] Instalando dependências do frontend (npm)..."
npm install

echo ""
echo "=============================================="
echo "  Pronto. Use: source venv/bin/activate"
echo "  Depois: ./ada_ctl.sh start   ou   npm run dev"
echo "=============================================="
