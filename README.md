# 처음 시작하는 macOS 터미널 설정

터미널을 처음 쓰는 사람도 명령 한 번으로 보기 편하고 쓰기 쉬운 환경을 만들 수 있습니다.

설치가 끝나면 다음과 같이 달라집니다.

- 현재 폴더와 Git 상태가 프롬프트에 보기 좋게 표시됩니다.
- 전에 입력했던 명령이 자동으로 제안됩니다.
- 실행할 수 있는 명령과 오타가 색으로 구분됩니다.
- 자주 가는 폴더로 빠르게 이동할 수 있습니다.
- 파일 목록과 파일 내용을 더 읽기 좋게 볼 수 있습니다.

처음에는 아래의 **설치하기**만 그대로 따라 하세요. 익숙해진 뒤 나머지 내용을 하나씩 사용해 보면 됩니다.

> 이 설정은 **macOS 전용**입니다. 기존 설정 파일은 설치 전에 자동으로 백업하며, 같은 설치 명령을 여러 번 실행해도 설정이 중복되지 않습니다.

## 설치하기

### 1. 터미널 열기

`⌘ Command + Space`를 누르고 `터미널`을 검색한 다음 **터미널.app**을 실행합니다.

Ghostty, iTerm2처럼 이미 사용 중인 터미널 앱이 있다면 그 앱에서 진행해도 됩니다.

### 2. 설치 명령 실행하기

아래 명령 전체를 복사해 터미널에 붙여넣고 `Enter`를 누릅니다.

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/seob717/mac-terminal-setup/main/setup.sh)"
```

설치 중에는 다음과 같은 입력을 요청할 수 있습니다.

- **Mac 로그인 비밀번호:** 입력해도 화면에 글자나 점이 나타나지 않습니다. 정상 동작이므로 비밀번호를 입력하고 `Enter`를 누르세요.
- **계속 진행할지 묻는 메시지:** 안내에 `RETURN`을 누르라고 나오면 `Enter`를 누르세요.
- **자동화 권한:** 터미널.app의 폰트를 자동으로 바꾸기 위한 요청입니다. 허용하면 설정이 자동으로 적용됩니다.

이미 설치된 도구는 건너뛰므로 `이미 설치됨`이라는 메시지가 보여도 문제없습니다.

### 3. 새 설정 적용하기

설치 마지막에 `셋업 완료`가 보이면 다음 명령을 실행합니다.

```bash
exec zsh
```

터미널 입력 줄의 모양이 바뀌면 설정이 적용된 것입니다. 터미널.app을 사용한다면 새 창(`⌘N`)을 열어야 폰트가 확실히 반영될 수 있습니다.

### 4. 아이콘 확인하기

아래 명령을 실행합니다.

```bash
echo -e "\ue0a0  \uf07c  \uf09b  \ue702  \ue7a8  \uf308"
```

아이콘 6개가 보이면 설치가 끝났습니다. 아이콘 대신 `□`나 `?`가 보인다면 [아이콘이 네모로 보여요](#아이콘이-네모로-보여요)를 확인하세요.

## 설치 후 하나씩 사용해 보기

명령을 모두 외울 필요는 없습니다. 아래 예제를 직접 몇 번 실행하며 익혀 보세요.

### 현재 위치 확인하기: `pwd`

```bash
pwd
```

지금 터미널이 어느 폴더를 보고 있는지 보여줍니다. 터미널은 항상 특정 폴더 안에서 명령을 실행합니다.

### 파일과 폴더 보기: `ls`, `ll`

```bash
ls
```

현재 폴더의 파일과 폴더를 간단히 보여줍니다.

```bash
ll
```

숨김 파일, 파일 크기, 수정 시각과 Git 상태까지 자세히 보여줍니다. 이 설정에서는 기본 `ls`보다 보기 좋은 **eza**가 두 명령을 대신 실행합니다.

### 폴더 이동하기: `cd`, `z`

먼저 기본 명령인 `cd`로 몇 군데를 방문해 봅니다.

```bash
cd ~/Downloads
cd ~
```

`~`는 내 사용자 폴더를 뜻합니다. **zoxide**는 이렇게 방문한 폴더를 기억합니다. 이후에는 폴더 이름의 일부만 입력해도 이동할 수 있습니다.

```bash
z Down
```

`z`는 사용할수록 자주 가는 폴더를 더 정확하게 찾아줍니다.

### 파일 내용 보기: `cat`

```bash
cat ~/.zshrc
```

파일 내용을 터미널에 보여줍니다. 이 설정에서는 **bat**가 `cat`을 대신해 내용을 색으로 구분하고 읽기 좋게 표시합니다. 파일 자체를 수정하지는 않습니다.

### 파일 안의 글자 찾기: `rg`

```bash
rg "terminal-setup" ~/.zshrc
```

파일에서 원하는 글자를 찾습니다. **ripgrep**의 명령 이름이 `rg`입니다.

### 이전 명령 다시 사용하기

방금 실행한 명령의 앞부분을 다시 입력해 보세요. 전에 사용한 명령이 회색으로 나타나면 `→` 방향키를 눌러 나머지를 완성할 수 있습니다.

`↑` 방향키를 누르면 이전에 실행한 명령을 순서대로 불러옵니다.

## 무엇이 설치되나요?

각 도구의 이름보다 **무엇이 편해지는지**를 먼저 기억하면 됩니다.

| 설치 요소 | 하는 일 | 사용할 때 |
|---|---|---|
| **Homebrew** | macOS용 프로그램 설치 관리자 | 이후 다른 도구를 설치할 때 `brew install 이름` 사용 |
| **Starship** | 명령을 입력하는 줄인 프롬프트를 꾸밈 | 현재 폴더, Git 상태, Node.js 버전, 오래 걸린 명령의 실행 시간 확인 |
| **zsh-autosuggestions** | 이전 명령을 회색 글자로 미리 제안 | 제안이 맞으면 `→`로 완성 |
| **zsh-syntax-highlighting** | 입력 중인 명령을 색으로 구분 | 실행하기 전에 명령 오타 확인 |
| **zoxide** | 방문한 폴더를 기억 | `z 폴더이름일부`로 빠르게 이동 |
| **eza** | 기본 `ls`보다 보기 좋은 파일 목록 | `ls` 또는 `ll` 실행 |
| **bat** | 기본 `cat`보다 읽기 좋은 파일 내용 | `cat 파일경로` 실행 |
| **ripgrep** | 파일과 폴더에서 빠르게 글자 검색 | `rg "찾을말" 경로` 실행 |
| **Hack Nerd Font** | 터미널용 아이콘이 포함된 글꼴 | 필요한 터미널에서만 자동 설치 |

### Starship에 표시되는 Git 상태

Git을 사용하는 폴더에서는 프롬프트에 현재 브랜치와 파일 상태가 나타납니다.

| 표시 | 뜻 |
|---|---|
| `modified` | 파일 내용이 바뀜 |
| `new` | 새 파일이 생김 |
| `staged` | 커밋할 파일로 선택됨 |
| `deleted` | 파일이 삭제됨 |
| `conflict` | Git 충돌을 해결해야 함 |
| `ahead` / `behind` | 원격 저장소보다 앞서거나 뒤처짐 |

Git을 사용하지 않는다면 이 표는 지금 건너뛰어도 됩니다.

## 자주 겪는 문제

### 아이콘이 네모로 보여요

폰트는 설치됐지만 현재 터미널 앱에서 사용하도록 지정되지 않은 경우가 많습니다.

- **터미널.app:** 새 창(`⌘N`)을 먼저 열어 봅니다. 계속 깨지면 `터미널 → 설정 → 프로파일 → 텍스트 → 폰트`에서 `Hack Nerd Font Mono`를 선택합니다.
- **iTerm2 또는 VS Code:** 앱의 폰트 설정에서 `Hack Nerd Font Mono`를 직접 선택합니다.
- **Ghostty, WezTerm, kitty:** Nerd Font 아이콘이 내장되어 있으므로 별도 폰트 설치가 필요하지 않습니다.

설정 후 터미널 앱을 완전히 종료했다가 다시 열고 아이콘 확인 명령을 실행하세요.

### `command not found`가 보여요

먼저 새 설정을 다시 불러옵니다.

```bash
exec zsh
```

그래도 같은 메시지가 나오면 설치 명령을 다시 실행해도 됩니다. 이미 완료된 항목은 건너뛰고 필요한 항목만 설치합니다.

### 설치 전 상태로 돌아가고 싶어요

설치 전에 `~/.zshrc`가 이미 있었다면 다음과 같은 이름으로 백업합니다.

```text
~/.zshrc.backup.날짜-시각
```

백업 파일을 확인하려면 다음 명령을 사용합니다.

```bash
find "$HOME" -maxdepth 1 -name '.zshrc.backup.*' -print | sort -r
```

결과가 없다면 설치 전에 `.zshrc`가 없었던 것입니다. 백업을 직접 복원하거나, 아래의 [설정 제거하기](#설정-제거하기)를 사용할 수 있습니다.

## 기존 터미널 설정이 있던 경우

기존 `.zshrc` 내용은 그대로 보존됩니다. 따라서 oh-my-zsh, agnoster, autojump 같은 예전 설정을 사용했다면 역할이 겹치는 줄이 남을 수 있습니다.

먼저 정리될 내용을 미리 확인합니다. 이 명령만으로는 파일을 바꾸지 않습니다.

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/seob717/mac-terminal-setup/main/migrate.sh)"
```

출력 내용을 확인한 뒤 실제로 정리하려면 다음 명령을 실행합니다.

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/seob717/mac-terminal-setup/main/migrate.sh)" -- --apply
```

이 작업은 중복된 플러그인 설정을 주석 처리하고, autojump 방문 기록이 있다면 zoxide로 가져옵니다. 원래 줄을 삭제하지 않으며 작업 전 `.zshrc`를 백업합니다.

oh-my-zsh까지 사용하지 않도록 바꾸려면 `--remove-omz` 옵션을 추가할 수 있습니다. 다만 `gst`, `gco` 같은 oh-my-zsh의 Git 단축 명령도 사라지므로 잘 모른다면 그대로 두는 편이 안전합니다.

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/seob717/mac-terminal-setup/main/migrate.sh)" -- --apply --remove-omz
```

## 설정 제거하기

먼저 무엇이 제거되는지만 확인합니다. 파일은 바뀌지 않습니다.

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/seob717/mac-terminal-setup/main/uninstall.sh)"
```

내용을 확인한 뒤 이 프로젝트가 추가한 `.zshrc` 설정과 Starship 설정을 제거합니다.

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/seob717/mac-terminal-setup/main/uninstall.sh)" -- --apply
exec zsh
```

Homebrew로 설치한 도구와 폰트는 다른 프로그램에서도 사용할 수 있으므로 기본적으로 남겨 둡니다. 그것까지 모두 제거하려면 다음 명령을 사용합니다.

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/seob717/mac-terminal-setup/main/uninstall.sh)" -- --apply --all
```

`migrate.sh`가 비워 둔 기존 oh-my-zsh 테마 이름은 자동으로 복원할 수 없습니다. 필요한 경우 설치 과정에서 만든 `.zshrc.backup.*` 파일에서 원래 값을 확인하세요.

## 원하는 항목만 설치하기

대부분의 사용자는 기본 설치 명령만 사용하면 됩니다. 아래 옵션은 필요한 경우에만 참고하세요.

| 옵션 | 용도 |
|---|---|
| `--no-cli` | zoxide, eza, bat, ripgrep을 설치하지 않음 |
| `--no-font` | Hack Nerd Font를 설치하지 않음 |
| `--font` | 터미널 자동 판단과 관계없이 폰트를 설치함 |
| `--terminal` | 현재 다른 앱을 사용 중이어도 터미널.app의 폰트와 프로파일을 설정함 |
| `--no-terminal` | 터미널.app 설정을 바꾸지 않음 |
| `--font-size 14` | 터미널.app의 폰트 크기를 지정함. 기본값은 13 |

인터넷에서 바로 실행할 때는 옵션 앞에 `--`를 한 번 더 넣습니다.

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/seob717/mac-terminal-setup/main/setup.sh)" -- --font-size 14
```

저장소를 내려받아 실행할 때는 다음과 같이 사용합니다.

```bash
git clone https://github.com/seob717/mac-terminal-setup.git
cd mac-terminal-setup
./setup.sh --font-size 14
```

## 내 설정은 어떻게 보호되나요?

- `setup.sh`는 `.zshrc`의 `# >>> terminal-setup >>>`와 `# <<< terminal-setup <<<` 사이만 관리합니다.
- 개인 설정은 이 블록 바깥에 작성하면 다시 설치해도 유지됩니다.
- 기존 `.zshrc`가 있다면 설치할 때마다 `~/.zshrc.backup.<날짜>-<시각>` 백업을 만듭니다.
- 기존 Starship 설정이 있다면 `~/.config/starship.toml.backup.<날짜>-<시각>`으로 백업합니다.
- `migrate.sh`는 정리할 줄을 삭제하지 않고 `# [migrated]`를 붙여 주석 처리합니다.
- `uninstall.sh`는 실제 제거 전에 미리보기를 제공합니다.

## 조금 더 알아보기

설치 후에는 `~/.zshrc`에 다음 순서로 도구가 연결됩니다.

1. Homebrew 명령 경로 등록
2. `Tab` 자동완성 준비
3. `ls`, `ll`, `cat` 단축 설정
4. Starship 프롬프트 시작
5. zoxide 폴더 이동 기능 시작
6. 이전 명령 자동 제안
7. 명령 문법 색상 표시

순서에는 도구 간 동작 조건이 있으므로 관리 블록 안쪽은 직접 수정하지 않는 것이 좋습니다. 개인 alias나 환경 변수는 블록 바깥에 추가하세요.

다른 Mac으로 옮길 때는 `~/.zshrc`와 `~/.config/starship.toml`을 복사하면 주요 설정을 재사용할 수 있습니다. 터미널 앱의 폰트 설정은 새 Mac에서 다시 지정해야 할 수 있습니다.

확인 기준: macOS 26 Tahoe · Homebrew 6 · Starship 1.26 · Ghostty 1.3 (2026년 8월)
