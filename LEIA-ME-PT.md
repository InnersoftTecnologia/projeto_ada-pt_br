# Ada V2 — Guia em Português

**Projeto original:** [Nazir Louis](https://github.com/nazirlouis) — [ada_v2](https://github.com/nazirlouis/ada_v2). O mérito da criação é todo dele. Este repositório é apenas a tradução e adaptação para português brasileiro.

---

## Scripts de automação

### 1. `./setup_venv.sh` — Criar o ambiente (venv) automaticamente

Cria o ambiente virtual Python (`venv/`), instala dependências (`pip install -r requirements.txt`), instala o Chromium do Playwright, cria `.env` a partir de `.env.example` se não existir e roda `npm install`.

**No Linux**, o PyAudio precisa dos headers do PortAudio. Antes de rodar o script, instale:
```bash
# Debian/Ubuntu
sudo apt install portaudio19-dev
```
Depois:
```bash
./setup_venv.sh
```

### 2. `./ada_ctl.sh` — Iniciar, parar, reiniciar e ver status

| Comando | Descrição |
|--------|------------|
| `./ada_ctl.sh start`   | Sobe o backend (com venv) e, em seguida, o frontend/Electron (`npm run dev`). |
| `./ada_ctl.sh stop`    | Encerra backend, Vite e Electron (por porta e por PID). |
| `./ada_ctl.sh restart` | Para e sobe de novo. |
| `./ada_ctl.sh status`  | Mostra se backend (porta 8000) e frontend (porta 5173) estão em execução. |

Exemplo:
```bash
./ada_ctl.sh start    # inicia o projeto
./ada_ctl.sh status   # confere se está rodando
./ada_ctl.sh stop     # encerra tudo
```

---

## Rodar o projeto (passo a passo manual)

1. **Ambiente Python (3.11)**  
   Crie e ative o ambiente:
   ```bash
   conda create -n ada_v2 python=3.11 -y && conda activate ada_v2
   ```
   No Linux, instale portaudio (ex.: `sudo apt install portaudio19-dev` ou `libportaudio2`).

2. **Dependências Python**
   ```bash
   pip install -r requirements.txt
   playwright install chromium
   ```

3. **Frontend**
   ```bash
   npm install
   ```

4. **Chave da API Gemini**  
   Crie o arquivo `.env` na pasta raiz do projeto (ou edite o que foi criado pelo `npm run dev`):
   ```
   GEMINI_API_KEY=sua_chave_aqui
   ```
   Obtenha a chave em: https://aistudio.google.com/app/apikey

5. **Subir o app**
   ```bash
   conda activate ada_v2
   npm run dev
   ```
   O backend Python sobe sozinho; a janela Electron abre quando tudo estiver pronto.

## Interface em português

A interface e as mensagens da Ada estão em **português do Brasil**.

## Capacidades desativadas por padrão

Por padrão estão **desativadas** (por não precisar de impressora nem CAD paramétrico):

- **Impressão 3D** — botão e funcionalidade de impressora não aparecem.
- **CAD paramétrico** — botão e geração de modelos 3D não aparecem.

Para ativar, edite `backend/settings.json` (criado na primeira execução) e use:
```json
"cad_enabled": true,
"printer_enabled": true
```
Reinicie o app após alterar.

## O que funciona sem CAD/impressora

- Voz e resposta da Ada (Gemini)
- Chat por texto
- Agente web (navegação/automação)
- Casa inteligente (dispositivos Kasa)
- Projetos e memória
- Câmera e gestos (se configurados)
- Autenticação por rosto (opcional)
