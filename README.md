# macOS 터미널 셋업

새 맥에서 명령 한 번으로 zsh 환경을 갖춘다. clone 없이 바로 실행할 수 있다.

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/seob717/mac-terminal-setup/main/setup.sh)"
exec zsh
```

옵션은 `--` 뒤에 붙인다.

```bash
bash -c "$(curl -fsSL .../setup.sh)" -- --no-cli
```

> `curl ... | bash` 대신 `bash -c "$(curl ...)"` 를 쓴다. 파이프로 넘기면 stdin이 스크립트로 채워져서, Homebrew 설치 중 비밀번호를 물어볼 때 입력을 받지 못한다.

clone해서 쓰려면:

```bash
git clone https://github.com/seob717/mac-terminal-setup.git
cd mac-terminal-setup && ./setup.sh
```

확인 기준: macOS 26 Tahoe · Homebrew 6 · Starship 1.26 · Ghostty 1.3 (2026-08)

## 설치되는 것

| 도구 | 역할 |
|---|---|
| **Starship** | 프롬프트. 경로, git 브랜치·상태, 실행 시간 표시 |
| **zsh-autosuggestions** | 예전에 친 명령을 회색으로 미리 표시 (`→` 키로 완성) |
| **zsh-syntax-highlighting** | 유효한 명령은 초록, 오타는 빨강 |
| **Hack Nerd Font** | 아이콘 글리프. 필요한 터미널에서만 설치 |
| **zoxide** | `cd` 대체. `z proj` 로 자주 가는 폴더에 점프 |
| **eza** | `ls` 대체. 아이콘 + git 상태 |
| **bat** | `cat` 대체. 문법 강조 |
| **ripgrep** | `grep` 대체. 훨씬 빠름 |

Homebrew가 없으면 먼저 설치한다. **oh-my-zsh는 쓰지 않는다** — 테마는 Starship이, 플러그인 로딩은 `.zshrc` 두 줄이 대신한다. 이미 깔려 있어도 건드리지 않는다.

### 폰트는 터미널을 보고 알아서 판단한다

| 터미널 | Nerd Font | 폰트 지정 |
|---|---|---|
| Terminal.app | 설치 | 스크립트가 자동 적용 |
| iTerm2, VS Code | 설치 | 직접 지정 필요 |
| Ghostty, WezTerm, kitty | 불필요 (내장) | 불필요 |

Ghostty는 1.2.0부터 `Symbols Nerd Font`를 바이너리에 내장해서 폰트를 안 깔아도 아이콘이 나온다.

## 옵션

```bash
./setup.sh --no-cli        # CLI 도구 없이 코어만
./setup.sh --no-font       # Nerd Font 설치 안 함
./setup.sh --font          # 자동 판단 무시하고 무조건 설치
./setup.sh --terminal      # Terminal.app을 무조건 설정 (폰트도 함께 설치)
./setup.sh --no-terminal   # Terminal.app 설정 건드리지 않음
./setup.sh --font-size 14  # Terminal.app 폰트 크기 (기본 13)
```

`--terminal`은 다른 터미널을 쓰면서 Terminal.app을 미리 준비해둘 때 쓴다. 예를 들어 Ghostty에서 실행해도 Terminal.app의 모든 프로파일에 Nerd Font가 적용된다.

## 기존 환경에서 갈아타기

`setup.sh`는 기존 `.zshrc`를 보존하므로 예전 설정이 죽은 코드로 남는다. `migrate.sh`가 그걸 정리한다.

```bash
./migrate.sh            # 미리보기 (파일을 바꾸지 않는다)
./migrate.sh --apply    # 적용
```

curl로도 같다.

```bash
RAW=https://raw.githubusercontent.com/seob717/mac-terminal-setup/main
bash -c "$(curl -fsSL $RAW/migrate.sh)"              # 미리보기
bash -c "$(curl -fsSL $RAW/migrate.sh)" -- --apply   # 적용
```

정리 대상은 `ZSH_THEME`, 중복된 플러그인 `source` 줄, agnoster 전용 `prompt_context()`, 그리고 autojump(이력을 zoxide로 가져온 뒤 플러그인 목록에서 제외).

oh-my-zsh까지 걷어내려면 `--remove-omz`를 붙인다. `gst`, `gco` 같은 git 단축 alias를 잃게 되므로 기본값은 아니다.

## 되돌리기

`uninstall.sh`가 `setup.sh`와 `migrate.sh`가 한 일을 되돌린다. 여기도 기본은 미리보기다.

```bash
./uninstall.sh              # 미리보기
./uninstall.sh --apply      # .zshrc 블록, migrated 주석, starship.toml 제거
./uninstall.sh --apply --all  # brew 패키지와 폰트까지 전부
```

`--all` 없이는 brew 패키지(`ripgrep`, `bat` 등)와 폰트를 건드리지 않는다. 다른 도구가 함께 쓰고 있을 수 있기 때문이다.

`migrate.sh`가 `# [migrated]`로 주석 처리한 줄은 태그를 떼어 원래대로 되살린다. 다만 `ZSH_THEME`은 값 자체를 비우는 방식이라 원래 테마 이름을 복원할 수 없다. 백업 파일을 보고 직접 채워야 한다.

## 안전장치

- `.zshrc`는 `# >>> terminal-setup >>>` 마커 블록 안쪽만 관리한다. 블록 밖의 개인 설정은 그대로 둔다.
- 여러 번 실행해도 블록이 중복되지 않는다.
- 실행할 때마다 `~/.zshrc.backup.<날짜>-<시각>` 백업을 남긴다.
- `migrate.sh`는 줄을 지우지 않고 `# [migrated]` 를 붙여 주석 처리한다.

되돌리려면 백업을 복원한다.

```bash
cp ~/.zshrc.backup.20260814-003929 ~/.zshrc
```

## .zshrc 로드 순서

블록 안의 순서는 취향이 아니라 각 도구의 요구사항이다.

1. Homebrew 환경 변수
2. `compinit` — 탭 자동완성 초기화 (oh-my-zsh가 이미 했으면 건너뜀)
3. alias
4. `starship init`
5. `zoxide init` — **compinit 이후여야** 자동완성이 등록된다
6. zsh-autosuggestions
7. zsh-syntax-highlighting — **반드시 맨 마지막.** 다른 플러그인의 키 바인딩을 덮는다

## 설치 후 확인

아이콘 6개가 깨지지 않으면 정상이다.

```bash
echo -e "\ue0a0  \uf07c  \uf09b  \ue702  \ue7a8  \uf308"
```

`□`로 보이면 폰트는 깔렸지만 터미널 앱에서 지정하지 않은 것이다. 설정에서 폰트를 `Hack Nerd Font Mono`로 바꾼다.

## 다른 머신으로 옮기기

`~/.zshrc` 와 `~/.config/starship.toml` 두 파일이면 복원된다. 경로를 하드코딩하지 않아 Intel·Apple Silicon 모두 동작한다. 터미널 앱의 폰트 설정만 머신마다 다시 적용하면 된다.
