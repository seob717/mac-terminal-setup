#!/usr/bin/env bash
#
# 기존 zsh 환경(oh-my-zsh, agnoster, autojump 등)에서 이 셋업으로 갈아탈 때
# 남아 있는 설정을 정리한다.
#
#   ./migrate.sh            무엇을 바꿀지 보여주기만 한다 (기본값)
#   ./migrate.sh --apply    실제로 적용한다
#
# setup.sh를 먼저 실행한 뒤에 쓰는 것을 전제로 한다.
# 줄을 지우지 않고 주석 처리하므로 마음에 안 들면 되돌리기 쉽다.

set -euo pipefail

readonly ZSHRC="$HOME/.zshrc"
readonly MARK_START="# >>> terminal-setup >>>"
readonly MARK_END="# <<< terminal-setup <<<"
readonly TAG="# [migrated] "
readonly STAMP="$(date +%Y%m%d-%H%M%S)"

APPLY=0
REMOVE_OMZ=0
FOUND=0   # 처리할 항목을 하나라도 찾았는지

if [[ -t 1 ]]; then
  C_INFO=$'\033[1;34m'; C_OK=$'\033[1;32m'; C_WARN=$'\033[1;33m'
  C_ERR=$'\033[1;31m'; C_DIM=$'\033[2m'; C_OFF=$'\033[0m'
else
  C_INFO=""; C_OK=""; C_WARN=""; C_ERR=""; C_DIM=""; C_OFF=""
fi

step() { printf '\n%s==>%s %s\n' "$C_INFO" "$C_OFF" "$*"; }
ok()   { printf '  %s✓%s %s\n' "$C_OK" "$C_OFF" "$*"; }
skip() { printf '  %s·%s %s\n' "$C_DIM" "$C_OFF" "$*"; }
warn() { printf '  %s!%s %s\n' "$C_WARN" "$C_OFF" "$*"; }
die()  { printf '\n%s에러:%s %s\n' "$C_ERR" "$C_OFF" "$*" >&2; exit 1; }

usage() {
  cat <<'USAGE'
사용법: ./migrate.sh [옵션]

기존 zsh 설정에서 이 셋업으로 갈아탈 때 남는 것들을 정리한다.
아무 옵션 없이 실행하면 무엇을 바꿀지 보여주기만 하고 파일은 건드리지 않는다.

옵션:
  --apply         실제로 적용한다 (적용 전 .zshrc를 백업한다)
  --remove-omz    oh-my-zsh 로드 줄까지 주석 처리한다
                  git 단축 alias(gst, gco 등)를 잃게 되므로 기본값은 아니다
  -h, --help      이 도움말

정리 대상:
  1. ZSH_THEME     Starship이 프롬프트를 그리므로 테마 설정은 죽은 코드가 된다
  2. 중복 플러그인  zsh-autosuggestions 등을 직접 source 하던 줄 (이중 로드 방지)
  3. prompt_context agnoster 테마 전용 함수라 Starship에서는 동작하지 않는다
  4. autojump      방문 이력을 zoxide로 가져오고 플러그인 목록에서 뺀다
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply)      APPLY=1; shift ;;
    --remove-omz) REMOVE_OMZ=1; shift ;;
    -h|--help)    usage; exit 0 ;;
    *)            die "알 수 없는 옵션: $1 (--help 참고)" ;;
  esac
done

[[ -f "$ZSHRC" ]] || die "$ZSHRC 가 없다. setup.sh를 먼저 실행할 것."

if ! grep -qF "$MARK_START" "$ZSHRC"; then
  warn "$ZSHRC 에 terminal-setup 블록이 없다. setup.sh를 먼저 실행하는 것을 권한다."
fi

# setup.sh가 관리하는 블록은 절대 건드리지 않는다.
# awk에 넘길 공통 전처리: 블록 안이면 in_block=1
readonly AWK_GUARD='
  index($0, MS) { in_block = 1 }
  index($0, ME) { in_block = 0; print; next }
'

# 블록 밖의 매칭 줄을 주석 처리한다
comment_lines() {
  local re="$1" tmp
  tmp="$(mktemp)"
  awk -v MS="$MARK_START" -v ME="$MARK_END" -v re="$re" -v tag="$TAG" "
    $AWK_GUARD
    in_block { print; next }
    \$0 ~ re && \$0 !~ /^[[:space:]]*#/ { print tag \$0; next }
    { print }
  " "$ZSHRC" > "$tmp" && mv "$tmp" "$ZSHRC"
}

backup_once() {
  [[ -n "${BACKED_UP:-}" ]] && return 0
  cp "$ZSHRC" "$ZSHRC.backup.$STAMP"
  ok "백업: $ZSHRC.backup.$STAMP"
  BACKED_UP=1
}

# ── 1. ZSH_THEME ──────────────────────────────────────────────────────────────
step "1. oh-my-zsh 테마 설정"
if grep -qE '^[[:space:]]*ZSH_THEME="[^"]+"' "$ZSHRC"; then
  FOUND=1
  current="$(grep -oE '^[[:space:]]*ZSH_THEME="[^"]+"' "$ZSHRC" | head -1)"
  if (( APPLY )); then
    backup_once
    tmp="$(mktemp)"
    sed 's/^\([[:space:]]*\)ZSH_THEME="[^"]*"/\1ZSH_THEME=""/' "$ZSHRC" > "$tmp" && mv "$tmp" "$ZSHRC"
    ok "$current → ZSH_THEME=\"\" 로 비웠다"
  else
    warn "$current → ZSH_THEME=\"\" 로 비운다"
  fi
else
  skip "정리할 테마 설정이 없다"
fi

# ── 2. 중복 플러그인 source ───────────────────────────────────────────────────
step "2. 직접 source 하던 zsh 플러그인"
PLUGIN_RE='source .*zsh-(autosuggestions|syntax-highlighting)\.zsh'
if grep -qE "^[[:space:]]*$PLUGIN_RE" "$ZSHRC"; then
  FOUND=1
  grep -nE "^[[:space:]]*$PLUGIN_RE" "$ZSHRC" | while IFS= read -r l; do
    printf '     %s\n' "$l"
  done
  if (( APPLY )); then
    backup_once
    comment_lines "$PLUGIN_RE"
    ok "주석 처리했다 (terminal-setup 블록이 대신 로드한다)"
  else
    warn "위 줄을 주석 처리한다 — 블록과 이중으로 로드되고 있다"
  fi
else
  skip "중복 로드 없음"
fi

# ── 3. prompt_context ─────────────────────────────────────────────────────────
step "3. agnoster 전용 prompt_context 함수"
if grep -qE '^[[:space:]]*prompt_context[[:space:]]*\(\)' "$ZSHRC"; then
  FOUND=1
  body="$(awk '/^[[:space:]]*prompt_context[[:space:]]*\(\)/,/^[[:space:]]*}/' "$ZSHRC" | head -5)"
  printf '%s\n' "$body" | sed 's/^/     /'
  if (( APPLY )); then
    backup_once
    tmp="$(mktemp)"
    awk -v tag="$TAG" '
      /^[[:space:]]*prompt_context[[:space:]]*\(\)/ { infn = 1 }
      infn { print tag $0; if ($0 ~ /^[[:space:]]*}/) infn = 0; next }
      { print }
    ' "$ZSHRC" > "$tmp" && mv "$tmp" "$ZSHRC"
    ok "주석 처리했다"
    warn "같은 문구를 Starship에서 쓰려면 ~/.config/starship.toml 에 custom 모듈을 넣으면 된다"
  else
    warn "위 함수를 주석 처리한다 — agnoster 전용이라 Starship에서는 호출되지 않는다"
  fi
else
  skip "prompt_context 없음"
fi

# ── 4. autojump → zoxide ──────────────────────────────────────────────────────
step "4. autojump 이력을 zoxide로"
AUTOJUMP_DB=""
for p in "$HOME/Library/autojump/autojump.txt" \
         "$HOME/.local/share/autojump/autojump.txt" \
         "$HOME/.autojump/share/autojump/autojump.txt"; do
  [[ -f "$p" ]] && { AUTOJUMP_DB="$p"; break; }
done

if [[ -n "$AUTOJUMP_DB" ]]; then
  FOUND=1
  entries="$(wc -l < "$AUTOJUMP_DB" | tr -d ' ')"
  if ! command -v zoxide >/dev/null 2>&1; then
    warn "autojump 이력 ${entries}개를 찾았지만 zoxide가 없다. setup.sh를 먼저 실행할 것."
  elif (( APPLY )); then
    # zoxide 0.10부터 import는 서브커맨드 방식이다 (--from 플래그는 사라졌다)
    if zoxide import autojump --merge >/dev/null 2>&1; then
      ok "autojump 이력 ${entries}개를 zoxide로 가져왔다"
    else
      warn "zoxide import에 실패했다. 'zoxide import autojump --merge'를 직접 실행해보라."
    fi
  else
    warn "autojump 이력 ${entries}개를 zoxide로 가져온다 ($AUTOJUMP_DB)"
  fi
else
  skip "autojump 이력 없음"
fi

# plugins=(...) 배열 안의 autojump 항목
if awk '/^[[:space:]]*plugins=\(/,/\)/' "$ZSHRC" | grep -qE '^[[:space:]]*autojump[[:space:]]*$'; then
  FOUND=1
  if (( APPLY )); then
    backup_once
    tmp="$(mktemp)"
    awk -v tag="$TAG" '
      /^[[:space:]]*plugins=\(/ { inarr = 1 }
      inarr && /^[[:space:]]*autojump[[:space:]]*$/ { print tag $0; next }
      inarr && /\)/ { inarr = 0 }
      { print }
    ' "$ZSHRC" > "$tmp" && mv "$tmp" "$ZSHRC"
    ok "plugins 목록에서 autojump를 뺐다"
    warn "명령 자체를 지우려면: brew uninstall autojump"
  else
    warn "plugins 목록의 autojump를 뺀다 (zoxide와 역할이 겹친다)"
  fi
fi

# ── 5. oh-my-zsh 로드 (선택) ──────────────────────────────────────────────────
step "5. oh-my-zsh 로드"
OMZ_RE='^[[:space:]]*(export ZSH=|source \$ZSH/oh-my-zsh\.sh|ZSH_THEME=|plugins=\()'
if grep -qE "$OMZ_RE" "$ZSHRC"; then
  if (( REMOVE_OMZ )); then
    FOUND=1
    if (( APPLY )); then
      backup_once
      tmp="$(mktemp)"
      awk -v MS="$MARK_START" -v ME="$MARK_END" -v tag="$TAG" '
        index($0, MS) { in_block = 1 }
        index($0, ME) { in_block = 0; print; next }
        in_block { print; next }
        # 이미 처리된 줄에 태그를 또 붙이지 않는다
        function mark(s) { return index(s, tag) == 1 ? s : tag s }
        /^[[:space:]]*plugins=\(/ { inarr = 1; print mark($0); next }
        inarr { print mark($0); if ($0 ~ /\)/) inarr = 0; next }
        /^[[:space:]]*(export ZSH=|source \$ZSH\/oh-my-zsh\.sh|ZSH_THEME=)/ { print mark($0); next }
        { print }
      ' "$ZSHRC" > "$tmp" && mv "$tmp" "$ZSHRC"
      ok "oh-my-zsh 로드 줄을 주석 처리했다"
      warn "git 단축 alias(gst, gco 등)가 사라진다. 필요하면 직접 alias를 추가할 것."
      warn "디렉토리까지 지우려면: rm -rf ~/.oh-my-zsh"
    else
      warn "oh-my-zsh 로드 줄을 모두 주석 처리한다"
      warn "  git 단축 alias(gst, gco 등)를 잃게 된다"
    fi
  else
    skip "oh-my-zsh를 유지한다 (--remove-omz로 정리 가능)"
  fi
else
  skip "oh-my-zsh 로드 줄 없음"
fi

# ── 마무리 ────────────────────────────────────────────────────────────────────
if (( ! FOUND )); then
  printf '\n%s정리할 것이 없다. 이미 깔끔한 상태다.%s\n' "$C_OK" "$C_OFF"
  exit 0
fi

if (( APPLY )); then
  printf '\n%s마이그레이션 완료%s\n\n' "$C_OK" "$C_OFF"
  cat <<EOF
새 설정을 적용한다:

    exec zsh

되돌리려면:

    cp $ZSHRC.backup.$STAMP $ZSHRC
EOF
else
  printf '\n%s위 내용은 미리보기다. 파일은 바뀌지 않았다.%s\n\n' "$C_WARN" "$C_OFF"
  cat <<'EOF'
실제로 적용하려면:

    ./migrate.sh --apply

oh-my-zsh까지 걷어내려면:

    ./migrate.sh --apply --remove-omz
EOF
fi
