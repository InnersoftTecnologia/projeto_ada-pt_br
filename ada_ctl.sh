#!/usr/bin/env bash
# ada_ctl.sh — Inicia, para, reinicia ou consulta o status do A.D.A V2.
# Uso: ./ada_ctl.sh { start | stop | restart | status }

set -e
cd "$(dirname "$0")"
PROJECT_ROOT="$(pwd)"
PID_FILE="${PROJECT_ROOT}/.ada.pid"
LOG_FILE="${PROJECT_ROOT}/.ada.log"

# Portas do backend e do Vite
BACKEND_PORT=8000
VITE_PORT=5173

# Encontra PIDs que escutam em uma porta (Linux)
pids_on_port() {
  local port="$1"
  if command -v lsof &>/dev/null; then
    lsof -ti ":$port" 2>/dev/null || true
  elif command -v ss &>/dev/null; then
    ss -tlnp 2>/dev/null | awk -v p=":$port" '$4 ~ p { gsub(/.*pid=/,""); gsub(/,.*/,""); print }' || true
  else
    fuser "$port/tcp" 2>/dev/null || true
  fi
}

# Mata processos que usam as portas do projeto
stop_ports() {
  local did=
  for port in $BACKEND_PORT $VITE_PORT; do
    for pid in $(pids_on_port "$port"); do
      [ -n "$pid" ] || continue
      echo "Encerrando processo $pid (porta $port)..."
      kill -TERM "$pid" 2>/dev/null || kill -9 "$pid" 2>/dev/null || true
      did=1
    done
  done
  # Mata processos Electron deste projeto
  if command -v pkill &>/dev/null; then
    pkill -f "electron.*$(basename "$PROJECT_ROOT")" 2>/dev/null || true
    pkill -f "electron.*ada" 2>/dev/null || true
  fi
  [ -n "$did" ] && sleep 2
}

status() {
  echo "=============================================="
  echo "  A.D.A V2 — Status"
  echo "=============================================="
  local backend_ok=0 vite_ok=0

  # Backend (porta 8000)
  if curl -s -o /dev/null -w "%{http_code}" "http://127.0.0.1:${BACKEND_PORT}/status" 2>/dev/null | grep -q 200; then
    echo "  Backend (porta $BACKEND_PORT): OK"
    backend_ok=1
  else
    echo "  Backend (porta $BACKEND_PORT): parado"
  fi

  # Vite (porta 5173)
  if curl -s -o /dev/null -w "%{http_code}" "http://127.0.0.1:${VITE_PORT}" 2>/dev/null | grep -qE '200|301|302'; then
    echo "  Frontend/Vite (porta $VITE_PORT): OK"
    vite_ok=1
  else
    echo "  Frontend/Vite (porta $VITE_PORT): parado"
  fi

  if [ "$backend_ok" -eq 1 ] && [ "$vite_ok" -eq 1 ]; then
    echo "  >>> Projeto em execução."
  else
    echo "  >>> Projeto parado ou incompleto."
  fi
  echo "=============================================="
}

start() {
  echo "=============================================="
  echo "  A.D.A V2 — Iniciando"
  echo "=============================================="

  if [ ! -d "venv" ]; then
    echo "Erro: venv não encontrado. Rode antes: ./setup_venv.sh"
    exit 1
  fi

  # Se o backend já está de pé, só sobe o frontend
  if curl -s -o /dev/null "http://127.0.0.1:${BACKEND_PORT}/status" 2>/dev/null; then
    echo "Backend já em execução na porta $BACKEND_PORT."
  else
    echo "Iniciando backend (venv) na porta $BACKEND_PORT..."
    (
      cd "$PROJECT_ROOT/backend"
      source "$PROJECT_ROOT/venv/bin/activate"
      export PYTHONPATH="${PROJECT_ROOT}/backend"
      exec python server.py
    ) >> "$LOG_FILE" 2>&1 &
    echo $! > "${PROJECT_ROOT}/.ada.backend.pid"
    # Espera o backend responder
    for i in $(seq 1 30); do
      if curl -s -o /dev/null "http://127.0.0.1:${BACKEND_PORT}/status" 2>/dev/null; then
        echo "Backend pronto."
        break
      fi
      sleep 1
      [ "$i" -eq 30 ] && echo "Aviso: backend demorou para responder. Seguindo mesmo assim."
    done
  fi

  echo "Iniciando frontend e Electron (npm run dev)..."
  npm run dev >> "$LOG_FILE" 2>&1 &
  echo $! > "$PID_FILE"
  echo "PID do npm guardado em $PID_FILE"
  echo ""
  echo "Aguardando Vite e Electron (alguns segundos)..."
  sleep 5
  status
}

stop() {
  echo "=============================================="
  echo "  A.D.A V2 — Parando"
  echo "=============================================="
  set +e
  # Mata processos pelas portas (backend e vite) e electron
  stop_ports
  # Mata pelo PID guardado, se existir
  if [ -f "$PID_FILE" ]; then
    local pid
    pid=$(cat "$PID_FILE" 2>/dev/null)
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
      echo "Encerrando processo npm (PID $pid)..."
      kill -TERM "$pid" 2>/dev/null || true
      sleep 2
    fi
    rm -f "$PID_FILE"
  fi
  if [ -f "${PROJECT_ROOT}/.ada.backend.pid" ]; then
    local pid
    pid=$(cat "${PROJECT_ROOT}/.ada.backend.pid" 2>/dev/null)
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
      kill -TERM "$pid" 2>/dev/null || true
    fi
    rm -f "${PROJECT_ROOT}/.ada.backend.pid"
  fi
  echo "Projeto encerrado."
  echo "=============================================="
  set -e
}

restart() {
  stop
  sleep 2
  start
}

case "${1:-}" in
  start)   start   ;;
  stop)    stop    ;;
  restart) restart ;;
  status)  status  ;;
  *)
    echo "Uso: $0 { start | stop | restart | status }"
    exit 1
    ;;
esac
