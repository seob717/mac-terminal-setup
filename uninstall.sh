#!/usr/bin/env bash
#
# setup.sh와 migrate.sh가 한 일을 되돌린다.
#
#   ./uninstall.sh            무엇을 지울지 보여주기만 한다 (기본값)
#   ./uninstall.sh --apply    실제로 지운다
#
# .zshrc의 관리 블록과 starship·Ghostty 설정을 지우고, migrate.sh가 주석 처리한
# 줄을 되살린다. brew 패키지와 폰트, Ghostty 앱 자체는 다른 작업에서도 쓸 수 있으므로
# 기본으로는 건드리지 않는다.

set -euo pipefail

readonly ZSHRC="$HOME/.zshrc"
readonly STARSHIP_TOML="$HOME/.config/starship.toml"
readonly GHOSTTY_CONFIG="$HOME/.config/ghostty/config"
readonly GHOSTTY_APP="/Applications/Ghostty.app"
readonly MARK_START="# >>> terminal-setup >>>"
readonly MARK_END="# <<< terminal-setup <<<"
readonly TAG="# [migrated] "
readonly STAMP="$(date +%Y%m%d-%H%M%S)"
readonly PACKAGES=(starship zsh-autosuggestions zsh-syntax-highlighting zoxide eza bat ripgrep)

APPLY=0
WITH_PACKAGES=0
WITH_FONT=0
WITH_GHOSTTY=0
FOUND=0

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
사용법: ./uninstall.sh [옵션]

setup.sh와 migrate.sh가 바꾼 것을 되돌린다.
아무 옵션 없이 실행하면 무엇을 지울지 보여주기만 하고 파일은 건드리지 않는다.

옵션:
  --apply       실제로 지운다 (지우기 전 .zshrc를 백업한다)
  --packages    brew 패키지도 지운다
                starship, zsh-autosuggestions, zsh-syntax-highlighting,
                zoxide, eza, bat, ripgrep
  --font        Hack Nerd Font도 지운다
  --ghostty     Ghostty 앱도 지운다 (설정 파일은 옵션 없이도 지운다)
  --all         --packages --font --ghostty 를 함께 켠다
  -h, --help    이 도움말

기본으로 지우는 것:
  1. .zshrc의 terminal-setup 블록
  2. migrate.sh가 붙인 # [migrated] 주석 (원래 줄로 되살린다)
  3. ~/.config/starship.toml
  4. ~/.config/ghostty/config
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply)    APPLY=1; shift ;;
    --packages) WITH_PACKAGES=1; shift ;;
    --font)     WITH_FONT=1; shift ;;
    --ghostty)  WITH_GHOSTTY=1; shift ;;
    --all)      WITH_PACKAGES=1; WITH_FONT=1; WITH_GHOSTTY=1; shift ;;
    -h|--help)  usage; exit 0 ;;
    *)          die "알 수 없는 옵션: $1 (--help 참고)" ;;
  esac
done

backup_once() {
  [[ -n "${BACKED_UP:-}" ]] && return 0
  cp "$ZSHRC" "$ZSHRC.backup.$STAMP"
  ok "백업: $ZSHRC.backup.$STAMP"
  BACKED_UP=1
}

# ── 1. .zshrc 관리 블록 ───────────────────────────────────────────────────────
step "1. .zshrc의 terminal-setup 블록"
if [[ -f "$ZSHRC" ]] && grep -qF "$MARK_START" "$ZSHRC"; then
  FOUND=1
  lines="$(awk -v s="$MARK_START" -v e="$MARK_END" '
    index($0, s) { inb = 1 } inb { n++ } index($0, e) { inb = 0 }
    END { print n + 0 }' "$ZSHRC")"
  if (( APPLY )); then
    backup_once
    tmp="$(mktemp)"
    awk -v s="$MARK_START" -v e="$MARK_END" '
      index($0, s) { skip = 1 }
      skip == 0    { print }
      index($0, e) { skip = 0 }
    ' "$ZSHRC" > "$tmp"
    # 블록을 걷어낸 뒤 끝에 남는 빈 줄을 정리한다
    awk '{ line[NR] = $0; if (NF) last = NR }
         END { for (i = 1; i <= last; i++) print line[i] }' "$tmp" > "$ZSHRC"
    rm -f "$tmp"
    ok "블록 ${lines}줄을 제거했다"
  else
    warn "블록 ${lines}줄을 제거한다"
  fi
else
  skip "관리 블록 없음"
fi

# ── 2. migrate.sh가 주석 처리한 줄 되살리기 ───────────────────────────────────
step "2. migrate.sh가 주석 처리한 줄"
if [[ -f "$ZSHRC" ]] && grep -qF "$TAG" "$ZSHRC"; then
  FOUND=1
  n="$(grep -cF "$TAG" "$ZSHRC")"
  grep -nF "$TAG" "$ZSHRC" | head -5 | sed 's/^/     /'
  (( n > 5 )) && printf '     ... 외 %d줄\n' "$((n - 5))"
  if (( APPLY )); then
    backup_once
    tmp="$(mktemp)"
    # 줄 맨 앞의 태그만 떼어내 원래 줄로 되돌린다
    awk -v tag="$TAG" '
      index($0, tag) == 1 { print substr($0, length(tag) + 1); next }
      { print }
    ' "$ZSHRC" > "$tmp" && mv "$tmp" "$ZSHRC"
    ok "${n}줄을 원래대로 되살렸다"
  else
    warn "위 ${n}줄에서 태그를 떼어 원래 줄로 되살린다"
  fi
else
  skip "되살릴 줄 없음"
fi

# migrate.sh는 ZSH_THEME을 주석이 아니라 빈 값으로 바꾼다. 원래 테마 이름이
# 파일에 남아 있지 않으므로 여기서는 되살릴 수 없다.
if [[ -f "$ZSHRC" ]] && grep -qE '^[[:space:]]*ZSH_THEME=""' "$ZSHRC"; then
  warn "ZSH_THEME이 빈 값이다. 원래 테마 이름은 복원할 수 없으니 직접 채울 것."
  warn "  예: ZSH_THEME=\"agnoster\"  (백업 파일에서 확인 가능)"
fi

# ── 3. starship 설정 ──────────────────────────────────────────────────────────
step "3. starship 설정 파일"
if [[ -f "$STARSHIP_TOML" ]]; then
  FOUND=1
  if (( APPLY )); then
    mv "$STARSHIP_TOML" "$STARSHIP_TOML.removed.$STAMP"
    ok "$STARSHIP_TOML.removed.$STAMP 로 옮겼다"
  else
    warn "$STARSHIP_TOML 을 제거한다 (.removed.$STAMP 로 남긴다)"
  fi
else
  skip "설정 파일 없음"
fi

# ── 4. Ghostty 설정 ───────────────────────────────────────────────────────────
# 설정 파일은 setup.sh가 만든 것이므로 기본으로 지운다.
# 앱 자체는 --ghostty를 줬을 때만 지운다. 지금 Ghostty에서 실행 중이라면
# 쓰고 있는 앱을 지우는 셈이라 건너뛴다.
step "4. Ghostty 설정 파일"
if [[ -f "$GHOSTTY_CONFIG" ]]; then
  FOUND=1
  if (( APPLY )); then
    mv "$GHOSTTY_CONFIG" "$GHOSTTY_CONFIG.removed.$STAMP"
    ok "$GHOSTTY_CONFIG.removed.$STAMP 로 옮겼다"
  else
    warn "$GHOSTTY_CONFIG 을 제거한다 (.removed.$STAMP 로 남긴다)"
  fi
else
  skip "설정 파일 없음"
fi

if (( WITH_GHOSTTY )); then
  if [[ ! -d "$GHOSTTY_APP" ]]; then
    skip "Ghostty 앱은 설치돼 있지 않음"
  elif [[ "${TERM_PROGRAM:-}" == "ghostty" ]]; then
    warn "지금 Ghostty에서 실행 중이라 앱은 그대로 둔다"
    warn "  다른 터미널에서 'brew uninstall --cask ghostty'를 실행할 것"
  else
    FOUND=1
    if (( APPLY )); then
      brew uninstall --cask ghostty >/dev/null 2>&1 \
        && ok "Ghostty 앱을 제거했다" \
        || warn "Ghostty 제거에 실패했다 (brew로 설치한 앱이 아닐 수 있다)"
    else
      warn "Ghostty 앱을 제거한다"
    fi
  fi
else
  skip "Ghostty 앱은 유지한다 (--ghostty로 제거 가능)"
fi

# ── 5. brew 패키지 (선택) ─────────────────────────────────────────────────────
step "5. brew 패키지"
if (( WITH_PACKAGES )); then
  if ! command -v brew >/dev/null 2>&1; then
    warn "brew를 찾을 수 없다"
  else
    installed=()
    for pkg in "${PACKAGES[@]}"; do
      brew list --formula --versions "$pkg" >/dev/null 2>&1 && installed+=("$pkg")
    done
    if (( ${#installed[@]} == 0 )); then
      skip "설치된 패키지 없음"
    else
      FOUND=1
      printf '     %s\n' "${installed[*]}"
      warn "ripgrep, bat 등은 다른 도구가 함께 쓸 수 있다"
      if (( APPLY )); then
        brew uninstall "${installed[@]}" >/dev/null 2>&1 \
          && ok "${#installed[@]}개 패키지를 제거했다" \
          || warn "일부 패키지 제거에 실패했다 (다른 패키지가 의존 중일 수 있다)"
      else
        warn "위 패키지를 제거한다"
      fi
    fi
  fi
else
  skip "brew 패키지는 유지한다 (--packages로 제거 가능)"
fi

# ── 6. 폰트 (선택) ────────────────────────────────────────────────────────────
step "6. Hack Nerd Font"
if (( WITH_FONT )); then
  if command -v brew >/dev/null 2>&1 && brew list --cask --versions font-hack-nerd-font >/dev/null 2>&1; then
    FOUND=1
    if (( APPLY )); then
      brew uninstall --cask font-hack-nerd-font >/dev/null 2>&1 \
        && ok "font-hack-nerd-font를 제거했다" || warn "폰트 제거에 실패했다"
      warn "터미널 앱의 폰트 설정은 그대로 남는다. 설정에서 직접 바꿀 것."
    else
      warn "font-hack-nerd-font를 제거한다"
      warn "  터미널 앱에서 이 폰트를 쓰고 있다면 글자가 깨져 보인다"
    fi
  else
    skip "설치돼 있지 않음"
  fi
else
  skip "폰트는 유지한다 (--font로 제거 가능)"
fi

# ── 마무리 ────────────────────────────────────────────────────────────────────
if (( ! FOUND )); then
  printf '\n%s지울 것이 없다. 이미 깨끗한 상태다.%s\n' "$C_OK" "$C_OFF"
  exit 0
fi

if (( APPLY )); then
  printf '\n%s제거 완료%s\n\n' "$C_OK" "$C_OFF"
  cat <<EOF
새 셸로 확인한다:

    exec zsh

되돌리려면:

    cp $ZSHRC.backup.$STAMP $ZSHRC
EOF
else
  printf '\n%s위 내용은 미리보기다. 파일은 바뀌지 않았다.%s\n\n' "$C_WARN" "$C_OFF"
  cat <<'EOF'
실제로 지우려면:

    ./uninstall.sh --apply

brew 패키지와 폰트, Ghostty까지 모두 지우려면:

    ./uninstall.sh --apply --all
EOF
fi
