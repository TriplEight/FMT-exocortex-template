#!/bin/bash
# Шаблон уведомлений: Стратег (R1)
# Вызывается из notify.sh через source

STRATEGY_DIR="${IWE_WORKSPACE:-$HOME/IWE}/${IWE_GOVERNANCE_REPO:-DS-strategy}/current"
STRATEGY_REPO_DIR="${IWE_WORKSPACE:-$HOME/IWE}/${IWE_GOVERNANCE_REPO:-DS-strategy}"
DATE=$(date +%Y-%m-%d)

find_strategy_file() {
    case "$1" in
        "day-plan"|"evening"|"day-close"|"note-review")
            echo "$STRATEGY_DIR/DayPlan $DATE.md"
            ;;
        "session-prep")
            ls -t "$STRATEGY_DIR"/WeekPlan\ W*.md 2>/dev/null | head -1
            ;;
        "week-review")
            ls -t "$STRATEGY_DIR"/WeekPlan\ W*.md 2>/dev/null | head -1
            ;;
        *)
            echo ""
            ;;
    esac
}

# HTML-escape для контента из markdown-источника (parse_mode=HTML).
# Применять к переменным, которые приходят из DayPlan/WeekPlan текста, ДО подстановки в printf.
# Не применять к статическим <b>/<a> тегам из printf — они должны остаться буквальными.
# Причина: фразы вида "<4/5", "a < b" в markdown ломают Telegram parser (Bad Request: Unsupported start tag).
escape_html() {
    python3 -c 'import sys, html; sys.stdout.write(html.escape(sys.stdin.read()))'
}

table_to_list() {
    local file="$1"
    local section="$2"
    # dayplan (EN): 🚦 | # | WP | h | Status (1 leading column)
    # weekplan (default): # | WP | Budget | Status | Deadline | Repo
    local format="${3:-weekplan}"

    awk -v s="## ${section}" -v t="${section}" \
        'index($0,s)==1 || ($0 ~ /<summary>/ && index($0,t)) {f=1;next}
         f && (/^## / || /<\/details>/) {exit}
         f' "$file" \
        | grep '^|' \
        | tail -n +3 \
        | sed -E 's/\[\[[^][]*\\?\|([^][]*)\]\]/\1/g' \
        | while IFS='|' read -r _ f1 f2 f3 f4 f5 f6 _rest; do
            local num rp hours status
            if [ "$format" = "dayplan" ]; then
                num="$f2"; rp="$f3"; hours="$f4"; status="$f5"
            else
                num="$f1"; rp="$f2"; hours="$f3"; status="$f4"
            fi
            num=$(echo "$num" | xargs)
            rp=$(echo "$rp" | xargs | sed 's/\*\*//g')
            hours=$(echo "$hours" | xargs | sed 's/\*\*//g')
            status=$(echo "$status" | xargs)

            local icon="⬜"
            case "$status" in
                *done*|*"✅"*) icon="✅" ;;
                *in_progress*|*in.progress*) icon="🔄" ;;
                *pending*) icon="⬜" ;;
            esac

            printf "%s #%s %s (%s)\n" "$icon" "$num" "$rp" "$hours"
        done
}

get_github_link() {
    local file="$1"
    local filename
    filename=$(basename "$file")
    local repo_url
    repo_url=$(cd "$STRATEGY_REPO_DIR" && git remote get-url origin 2>/dev/null | sed 's/\.git$//' | sed 's|git@\([^:]*\):|https://\1/|')
    if [ -n "$repo_url" ]; then
        local branch
        branch=$(cd "$STRATEGY_REPO_DIR" && git rev-parse --abbrev-ref HEAD 2>/dev/null)
        if [ -z "$branch" ]; then
            echo "ERROR: unable to determine git branch for $STRATEGY_REPO_DIR" >&2
            return 1
        fi
        local encoded_name
        encoded_name=$(printf '%s' "$filename" | python3 -c 'import sys,urllib.parse; print(urllib.parse.quote(sys.stdin.read().strip()))')
        printf '\n\n<a href="%s/blob/%s/current/%s">📄 Открыть в GitHub</a>' "$repo_url" "$branch" "$encoded_name"
    fi
}

build_message() {
    local scenario="$1"
    local file
    file=$(find_strategy_file "$scenario")

    if [ -z "$file" ] || [ ! -f "$file" ]; then
        echo ""
        return
    fi

    case "$scenario" in
        "day-plan")
            local title
            title=$(grep '^# ' "$file" | head -1 | sed 's/^# //' | escape_html)
            local plan_items
            plan_items=$(table_to_list "$file" "Plan for today" "dayplan" | escape_html)

            printf "<b>📋 %s</b>\n\n" "$title"
            printf "<b>Plan:</b>\n%s" "$plan_items"
            ;;

        "session-prep")
            local title
            title=$(grep '^# ' "$file" | head -1 | sed 's/^# //' | escape_html)
            local plan_items
            plan_items=$(table_to_list "$file" "Work products" | escape_html)
            [ -z "$plan_items" ] && plan_items=$(table_to_list "$file" "Plan for the week" | escape_html)

            printf "<b>📅 %s</b>\n\n" "$title"
            printf "<b>Work products:</b>\n%s" "$plan_items"
            ;;

        "week-review")
            local title
            title=$(grep '^# ' "$file" | head -1 | sed 's/^# //' | escape_html)

            printf "<b>📊 Week-Review завершён</b>\n\n%s" "$title"
            ;;

        "note-review")
            printf "<b>📝 Note-Review завершён</b>\n\nЗаметки обработаны, inbox почищен."
            ;;

        *)
            local title
            title=$(grep '^# ' "$file" | head -1 | sed 's/^# //' | escape_html)
            printf "<b>📋 %s</b>\n\nСценарий <b>%s</b> завершён." "$title" "$scenario"
            ;;
    esac

    get_github_link "$file"
}

build_buttons() {
    local scenario="$1"
    echo '[]'
}
