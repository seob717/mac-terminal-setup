#!/usr/bin/env bash
#
# macOS 터미널 원클릭 셋업
#
#   Homebrew → Nerd Font → 터미널 폰트 적용 → Starship → zsh 플러그인 → CLI 도구
#
# 기존 설정은 건드리지 않는다. .zshrc는 마커 블록 안쪽만 관리하므로
# 여러 번 실행해도 중복되지 않고, 실행 전 항상 백업을 남긴다.
#
# 확인 기준: macOS 26 Tahoe / Homebrew 6 / Starship 1.26 / Ghostty 1.3 (2026-08)

set -euo pipefail

readonly MARK_START="# >>> terminal-setup >>>"
readonly MARK_END="# <<< terminal-setup <<<"
readonly ZSHRC="$HOME/.zshrc"
readonly STARSHIP_TOML="$HOME/.config/starship.toml"
readonly STAMP="$(date +%Y%m%d-%H%M%S)"

WITH_CLI=1
WITH_FONT=auto      # auto | 1 | 0
WITH_TERMINAL=auto  # auto | 1 | 0
FONT_SIZE=13

# ── 로그 ──────────────────────────────────────────────────────────────────────
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
사용법: ./setup.sh [옵션]

옵션:
  --no-cli        현대식 CLI 도구(zoxide, eza, bat, ripgrep) 설치를 건너뛴다
  --font          Nerd Font를 무조건 설치한다 (자동 판단을 무시)
  --no-font       Nerd Font를 설치하지 않는다
  --terminal      Terminal.app 폰트·프로파일을 무조건 설정한다
                  (다른 터미널에서 실행하면서 Terminal.app을 준비할 때)
  --no-terminal   Terminal.app 폰트·프로파일 설정을 건드리지 않는다
  --font-size N   Terminal.app 폰트 크기 (기본 13)
  -h, --help      이 도움말

폰트와 Terminal.app 설정은 기본적으로 지금 쓰고 있는 터미널을 보고 알아서 판단한다.
Ghostty·WezTerm·kitty는 Nerd Font를 내장하고 있어 폰트 설치를 건너뛴다.

설치 내용:
  Homebrew, Starship(+ starship.toml),
  zsh-autosuggestions, zsh-syntax-highlighting
  [조건부] Hack Nerd Font
  [기본 포함] zoxide, eza, bat, ripgrep
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-cli)      WITH_CLI=0; shift ;;
    --font)        WITH_FONT=1; shift ;;
    --no-font)     WITH_FONT=0; shift ;;
    --terminal)    WITH_TERMINAL=1; shift ;;
    --no-terminal) WITH_TERMINAL=0; shift ;;
    --font-size)
      FONT_SIZE="${2:-}"
      [[ "$FONT_SIZE" =~ ^[0-9]+$ ]] || die "--font-size는 숫자여야 한다 (받은 값: '${2:-없음}')"
      shift 2 ;;
    -h|--help)     usage; exit 0 ;;
    *)             die "알 수 없는 옵션: $1 (--help 참고)" ;;
  esac
done

[[ "$(uname -s)" == "Darwin" ]] || die "이 스크립트는 macOS 전용이다."

# ── 0. 터미널 판별 ────────────────────────────────────────────────────────────
# Nerd Font를 내장한 터미널에서는 폰트를 따로 설치할 필요가 없다.
# Ghostty는 바이너리에 Symbols Nerd Font를 담고 셀 렌더링에 쓴다 (1.2.0부터).
TERM_APP="${TERM_PROGRAM:-unknown}"
case "$TERM_APP" in
  ghostty|WezTerm|kitty) FONT_BUNDLED=1 ;;
  *)                     FONT_BUNDLED=0 ;;
esac

step "터미널 확인"
case "$TERM_APP" in
  Apple_Terminal) ok "Terminal.app — Nerd Font 설치와 폰트 적용이 모두 필요하다" ;;
  ghostty)        ok "Ghostty — Nerd Font가 내장돼 있어 폰트 설치가 필요 없다" ;;
  WezTerm|kitty)  ok "$TERM_APP — Nerd Font가 내장돼 있어 폰트 설치가 필요 없다" ;;
  iTerm.app)      ok "iTerm2 — Nerd Font 설치 후 앱에서 직접 폰트를 지정해야 한다" ;;
  unknown)        warn "터미널을 판별하지 못했다. 안전하게 Nerd Font를 설치한다." ;;
  *)              ok "$TERM_APP — Nerd Font 설치 후 앱에서 직접 폰트를 지정해야 한다" ;;
esac

# 자동 판단 확정 (명시적 플래그가 있으면 그대로 둔다)
[[ "$WITH_TERMINAL" == auto ]] \
  && { [[ "$TERM_APP" == "Apple_Terminal" ]] && WITH_TERMINAL=1 || WITH_TERMINAL=0; }

# Terminal.app을 설정하기로 했다면 폰트도 있어야 한다.
# (Ghostty에서 --terminal로 실행하는 경우처럼, 지금 터미널에 폰트가 내장돼 있어도 필요하다)
if [[ "$WITH_FONT" == auto ]]; then
  if (( WITH_TERMINAL )) || ! (( FONT_BUNDLED )); then WITH_FONT=1; else WITH_FONT=0; fi
fi

# ── 1. Homebrew ───────────────────────────────────────────────────────────────
step "Homebrew 확인"
if ! command -v brew >/dev/null 2>&1; then
  warn "Homebrew가 없다. 설치를 시작한다 (관리자 비밀번호를 물어볼 수 있다)."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# 방금 설치했다면 PATH에 아직 없으므로 직접 잡아준다 (Apple Silicon / Intel)
if ! command -v brew >/dev/null 2>&1; then
  for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    [[ -x "$candidate" ]] && eval "$("$candidate" shellenv)" && break
  done
fi
command -v brew >/dev/null 2>&1 || die "Homebrew 설치에 실패했다."

BREW_PREFIX="$(brew --prefix)"
ok "Homebrew: $BREW_PREFIX"

brew_formula() {
  local pkg="$1"
  if brew list --formula --versions "$pkg" >/dev/null 2>&1; then
    skip "$pkg (이미 설치됨)"
  else
    brew install "$pkg" >/dev/null && ok "$pkg 설치"
  fi
}

# ── 2. Nerd Font ──────────────────────────────────────────────────────────────
# 프롬프트의 git 브랜치 아이콘, eza의 파일 타입 아이콘을 그리려면 필요하다.
# 폰트 cask는 2024년에 homebrew/cask로 통합됐다. 예전 tap(homebrew/cask-fonts)은
# 이제 실행하면 곧바로 에러를 내므로 fallback으로도 쓰면 안 된다.
if (( WITH_FONT )); then
  step "Hack Nerd Font 설치"
  if brew list --cask --versions font-hack-nerd-font >/dev/null 2>&1; then
    skip "font-hack-nerd-font (이미 설치됨)"
  else
    brew install --cask font-hack-nerd-font >/dev/null \
      || die "폰트 설치 실패. 'brew install --cask font-hack-nerd-font'를 직접 실행해보라."
    ok "font-hack-nerd-font 설치"
  fi
else
  step "Hack Nerd Font 설치 (건너뜀 — 터미널에 내장돼 있거나 --no-font)"
fi

# ── 3. Starship + zsh 플러그인 ────────────────────────────────────────────────
step "Starship과 zsh 플러그인 설치"
brew_formula starship
brew_formula zsh-autosuggestions
brew_formula zsh-syntax-highlighting

# ── 4. CLI 도구 ───────────────────────────────────────────────────────────────
if (( WITH_CLI )); then
  step "현대식 CLI 도구 설치"
  brew_formula zoxide    # cd 대체: 방문 이력을 학습해 z <일부이름>으로 점프
  brew_formula eza       # ls 대체: 아이콘 + git 상태 컬럼
  brew_formula bat       # cat 대체: 문법 강조
  brew_formula ripgrep   # grep 대체: 훨씬 빠른 검색
else
  step "현대식 CLI 도구 설치 (--no-cli로 건너뜀)"
fi

# ── 5. starship.toml ──────────────────────────────────────────────────────────
# 디렉토리 + git + 실행 시간만 보여주는 미니멀 구성.
step "starship 설정 파일 생성"
mkdir -p "$(dirname "$STARSHIP_TOML")"
if [[ -f "$STARSHIP_TOML" ]]; then
  cp "$STARSHIP_TOML" "$STARSHIP_TOML.backup.$STAMP"
  warn "기존 설정을 $STARSHIP_TOML.backup.$STAMP 로 백업했다."
fi
cat > "$STARSHIP_TOML" <<'TOML'
# 디렉토리 · git · 실행 시간만 보여주는 미니멀 프롬프트.
# 항목을 더 넣고 싶으면 https://starship.rs/config 참고.

format = """
$directory\
$git_branch\
$git_status\
$cmd_duration\
$line_break\
$character"""

add_newline = true

[directory]
truncation_length = 3      # 경로가 길면 뒤 3단계만 표시
truncate_to_repo = true    # git 저장소 안에서는 저장소 루트 기준으로 표시
style = "bold cyan"

[git_branch]
# 아이콘은 글자를 직접 넣으면 편집기·복사 과정에서 깨지기 쉬워 이스케이프로 적는다.
# 이스케이프는 큰따옴표 문자열에서만 해석된다. 작은따옴표로 쓰면 문자 그대로 나온다.
symbol = "\ue0a0 "
style = "bold purple"

[git_status]
style = "bold yellow"

[cmd_duration]
min_time = 2000            # 2초 이상 걸린 명령만 소요 시간 표시
format = "took [$duration]($style) "
style = "bold yellow"

[character]
success_symbol = "[\u279c](bold green)"
error_symbol = "[\u279c](bold red)"
TOML
ok "$STARSHIP_TOML"

# ── 6. .zshrc ─────────────────────────────────────────────────────────────────
step ".zshrc 구성"

if [[ -f "$ZSHRC" ]]; then
  cp "$ZSHRC" "$ZSHRC.backup.$STAMP"
  ok "백업: $ZSHRC.backup.$STAMP"

  # 이미 다른 프롬프트 테마를 쓰고 있으면 알려준다.
  # (Starship이 뒤에서 로드되므로 동작은 하지만, 죽은 설정이 남는다)
  if grep -qE '^[[:space:]]*ZSH_THEME="[^"]+"' "$ZSHRC"; then
    warn "oh-my-zsh 테마(ZSH_THEME) 설정이 남아 있다. Starship이 프롬프트를 그리므로"
    warn "  ZSH_THEME=\"\" 로 비워두면 깔끔하다. (동작에는 지장 없음)"
  fi
  # 같은 플러그인을 직접 source 하고 있으면 이중 로드가 된다.
  if grep -qE '^[[:space:]]*source .*zsh-(autosuggestions|syntax-highlighting)\.zsh' "$ZSHRC"; then
    warn "zsh 플러그인을 이미 직접 source 하는 줄이 있다. 이 블록과 이중으로 로드되니"
    warn "  기존 줄을 지우는 편이 좋다."
  fi
else
  touch "$ZSHRC"
  ok "$ZSHRC 새로 생성"
fi

# 기존 마커 블록 제거 — 재실행 시 중복 방지
if grep -qF "$MARK_START" "$ZSHRC"; then
  tmp="$(mktemp)"
  awk -v s="$MARK_START" -v e="$MARK_END" '
    index($0, s) { skip = 1 }
    skip == 0    { print }
    index($0, e) { skip = 0 }
  ' "$ZSHRC" > "$tmp"
  mv "$tmp" "$ZSHRC"
  skip "기존 terminal-setup 블록을 교체한다"
fi

# 파일 끝의 빈 줄을 정리한다. 없으면 재실행할 때마다 빈 줄이 하나씩 쌓인다.
tmp="$(mktemp)"
awk '{ line[NR] = $0; if (NF) last = NR }
     END { for (i = 1; i <= last; i++) print line[i] }' "$ZSHRC" > "$tmp"
mv "$tmp" "$ZSHRC"

# 블록 생성. 경로를 박아 넣지 않고 실행 시점에 찾도록 해서
# Intel / Apple Silicon 어느 맥에 옮겨도 그대로 동작하게 한다.
# 도구가 빠져 있으면 조용히 건너뛴다 (셸 시작할 때마다 에러가 나지 않도록).
#
# 로드 순서에는 지켜야 할 제약이 있다:
#   - compinit은 zoxide보다 먼저 (zoxide가 자동완성을 등록하려면 필요)
#   - zsh-syntax-highlighting은 무조건 맨 마지막 (다른 플러그인의 키 바인딩을 덮는다)
{
  printf '\n%s\n' "$MARK_START"

  cat <<'CORE'
# 이 블록은 setup.sh가 관리한다. 안쪽을 직접 고치면 재실행 시 사라지므로,
# 개인 설정은 이 블록 바깥에 작성할 것.

# Homebrew 환경 변수. Apple Silicon(/opt/homebrew)과 Intel(/usr/local) 모두 대응하며,
# 이걸 빠뜨리면 brew로 설치한 명령을 "command not found"로 못 찾는다.
for _brew in /opt/homebrew/bin/brew /usr/local/bin/brew; do
  [[ -x "$_brew" ]] && eval "$("$_brew" shellenv)" && break
done
unset _brew

# 탭 자동완성 초기화. oh-my-zsh 같은 프레임워크가 이미 했다면 건너뛴다.
if ! typeset -f compdef >/dev/null; then
  autoload -Uz compinit && compinit
fi
CORE

  if (( WITH_CLI )); then
    cat <<'CLI'

# 기존 명령어를 현대식 도구로 교체. eza는 아이콘이 기본값이 아니라 --icons가 필요하다.
command -v eza >/dev/null && {
  alias ls='eza --icons --group-directories-first'
  alias ll='eza -lah --icons --git --group-directories-first'
}
command -v bat >/dev/null && alias cat='bat --style=plain --paging=never'
CLI
  fi

  cat <<'CORE2'

# 프롬프트 렌더링
command -v starship >/dev/null && eval "$(starship init zsh)"
CORE2

  if (( WITH_CLI )); then
    cat <<'CLI2'

# cd 대체: z <디렉토리 일부>로 자주 가는 곳으로 점프 (compinit 이후여야 한다)
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"
CLI2
  fi

  cat <<'TAIL'

# 입력한 명령을 이력에서 회색으로 미리 보여준다 (→ 키로 완성)
_plug="$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
[[ -f "$_plug" ]] && source "$_plug"

# 문법 강조는 다른 플러그인의 키 바인딩을 덮으므로 반드시 마지막에 로드한다
_plug="$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
[[ -f "$_plug" ]] && source "$_plug"
unset _plug
TAIL

  printf '%s\n' "$MARK_END"
} >> "$ZSHRC"
ok ".zshrc에 설정 블록을 추가했다"

# ── 7. Terminal.app 폰트 적용 ─────────────────────────────────────────────────
# 이 셋업에서 가장 흔한 실패 지점: 폰트를 설치해도 터미널 앱에서 지정하지 않으면
# 아이콘이 ? 또는 □ 로 깨진다. AppleScript로 자동 적용한다.
#
# 열려 있는 창은 자기 프로파일을 그대로 쓰기 때문에, 기본 프로파일만 바꾸면
# 정작 지금 보고 있는 창은 그대로여서 "실패한 것처럼" 보인다.
# 그래서 모든 프로파일에 폰트를 적용한다.
#
# 기본 프로파일은 macOS 26 Tahoe의 신규 다크 테마 'Clear Dark'를 우선 쓰고,
# 없으면(구버전 macOS) 'Pro'로 물러난다.
if (( WITH_TERMINAL )); then
  step "Terminal.app 폰트 적용"

  applied=""
  for psname in "HackNFM-Regular" "HackNF-Regular" "Hack-Regular"; do
    result="$(osascript <<EOF 2>/dev/null || true
tell application "Terminal"
  set targetName to "Pro"
  repeat with s in settings sets
    if name of s is "Clear Dark" then set targetName to "Clear Dark"
  end repeat

  repeat with s in settings sets
    try
      set font name of s to "$psname"
      set font size of s to $FONT_SIZE
    end try
  end repeat

  try
    set default settings to settings set targetName
    set startup settings to settings set targetName
  end try
  return (font name of default settings) & "|" & targetName
end tell
EOF
)"
    if [[ "$result" == "$psname|"* ]]; then
      applied="$psname"
      profile="${result#*|}"
      break
    fi
  done

  if [[ -n "$applied" ]]; then
    ok "모든 프로파일에 $applied ${FONT_SIZE}pt 적용, 기본값을 '${profile}'로 지정"
  else
    warn "자동 적용에 실패했다. 자동화 권한을 거부했거나 폰트 이름이 다를 수 있다."
    warn "  수동: Terminal → 설정 → 프로파일 → 텍스트 → 폰트 변경 → 'Hack Nerd Font Mono'"
  fi
elif (( WITH_FONT )); then
  step "터미널 폰트 지정"
  warn "'$TERM_APP'에서는 폰트를 직접 지정해야 아이콘이 깨지지 않는다."
  warn "  설정에서 폰트를 'Hack Nerd Font Mono'로 바꾼 뒤 터미널을 재시작할 것."
fi

# ── 완료 ──────────────────────────────────────────────────────────────────────
printf '\n%s셋업 완료%s\n\n' "$C_OK" "$C_OFF"
cat <<EOF
다음 명령으로 새 설정을 적용한다:

    exec zsh

적용 후 아래를 실행해 아이콘 6개가 깨지지 않는지 확인한다:

    echo -e "\\ue0a0  \\uf07c  \\uf09b  \\ue702  \\ue7a8  \\uf308"
EOF

if (( WITH_TERMINAL )); then
  cat <<'EOF'

폰트는 새로 여는 창부터 확실히 반영된다. 지금 창에서 아이콘이 깨져 보이면
⌘N으로 새 창을 열어 확인할 것.
EOF
fi

cat <<EOF

되돌리려면 백업 파일을 사용한다:

    cp $ZSHRC.backup.$STAMP $ZSHRC
EOF
