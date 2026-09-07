# Optional Components

Optional features that enhance IWE but are not required for core functionality.

---

## Локальный шлюз координации агентов (iwe-local-gateway)

Если в одной рабочей директории работает несколько ИИ-агентов одновременно (Claude Code, Kimi, Hermes) — нужен общий менеджер файловых блокировок, чтобы они не перезаписывали правки друг друга. Полное описание сценария — [docs/AGENT-VENDOR-SETUP.md](../../docs/AGENT-VENDOR-SETUP.md).

### Установка

```bash
bash setup/optional/setup-local-gateway.sh
```

Скрипт клонирует шлюз на закреплённую версию, собирает его, запускает демон и выводит блок для ручной вставки в `.mcp.json` (существующий файл не переписывается автоматически — только показывается точная запись для копирования). Повторный запуск безопасен: уже установленный шлюз не переустанавливается.

### Uninstall

```bash
kill "$(cat ~/.iwe/gateway.pid)"          # остановить демон
rm -rf ~/IWE/DS-MCP/local-gateway         # удалить код шлюза
rm -f ~/.iwe/gateway.sock ~/.iwe/gateway-daemon.log ~/.iwe/gateway.pid
```

Затем вручную удалите запись `iwe-local-gateway` из `.mcp.json`.

### Files

| File | Purpose |
|------|---------|
| `setup-local-gateway.sh` | клон + сборка + запуск демона + инструкция для `.mcp.json` |

---

## Day Rhythm Config

The file `memory/day-rhythm-config.yaml` controls several Day Open features:

- **Strategy day** — which day of the week to suggest a strategy session
- **Self-development slot** — always first in the daily plan
- **News digest** — optional news topics at Day Open (disabled by default)
- **Pomodoro settings** — break reminder thresholds

This file is read by Claude during Day Open (`protocol-open.md § День`). No installation needed — it works automatically once present in `memory/`.

---

## Cloud Scheduler (GitHub Actions)

IWE автоматика в облаке — работает даже когда Mac выключен. Базовый уровень: backup + health check. $0/мес.

Полная инструкция (доставляется через update.sh — issue #325): [docs/CLOUD-SCHEDULER.md](../../docs/CLOUD-SCHEDULER.md)

---

## Cover Images (S48)

Автоматическая генерация обложек для постов через OpenAI GPT Image API. Каждая обложка уникальна и отражает содержание статьи.

Подробная инструкция: [COVER-IMAGES.md](COVER-IMAGES.md)

### Quick start

```bash
# 1. Положите API key
echo "sk-proj-ВАШ_КЛЮЧ" > .secrets/openai-api-key

# 2. Установите зависимости
pip install httpx pyyaml

# 3. Сгенерируйте обложку
python setup/optional/generate-post-image.py path/to/post.md
```

### Files

| File | Purpose |
|------|---------|
| `generate-post-image.py` | Python-скрипт генерации (GPT Image 1) |
| `COVER-IMAGES.md` | Подробная инструкция: промпты, параметры, стоимость |
