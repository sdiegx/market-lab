#!/usr/bin/env bash
# MarketLab Unix setup (macOS + Linux)
# Installs mise via Homebrew on macOS when available, activates it, and runs project setup tasks.
# Run from project root:
#   bash ./scripts/unix-setup.sh

set -euo pipefail

SKIP_HOOKS="${SKIP_HOOKS:-0}"

step() {
    printf '\033[1;36m==> %s\033[0m\n' "$*"
}

have() {
    command -v "$1" >/dev/null 2>&1
}

find_mise() {
    if have mise; then
        command -v mise
    elif [ -x "$HOME/.local/bin/mise" ]; then
        echo "$HOME/.local/bin/mise"
    elif [ -x "/opt/homebrew/bin/mise" ]; then
        echo "/opt/homebrew/bin/mise"
    elif [ -x "/usr/local/bin/mise" ]; then
        echo "/usr/local/bin/mise"
    else
        return 1
    fi
}

# --- 1. Verify project root ----------------------------------------------------
if [ ! -f "mise.toml" ]; then
    echo "mise.toml not found. Run this script from the project root." >&2
    exit 1
fi

# --- 2. Detect shell rc file ---------------------------------------------------
detect_rc() {
    case "${SHELL:-}" in
        */zsh)  echo "$HOME/.zshrc" ;;
        */bash)
            if [ "$(uname -s)" = "Darwin" ]; then
                echo "$HOME/.bash_profile"
            else
                echo "$HOME/.bashrc"
            fi
            ;;
        *) echo "$HOME/.profile" ;;
    esac
}

detect_activate_cmd() {
    case "${SHELL:-}" in
        */zsh)  echo 'eval "$(mise activate zsh)"' ;;
        */bash) echo 'eval "$(mise activate bash)"' ;;
        *)      echo 'eval "$(mise activate bash)"' ;;
    esac
}

RC_FILE="$(detect_rc)"
ACTIVATE_CMD="$(detect_activate_cmd)"
MISE_BIN="$(find_mise || true)"

# --- 3. Install mise -----------------------------------------------------------
if [ -z "$MISE_BIN" ]; then
    if [ "$(uname -s)" = "Darwin" ] && have brew; then
        step "Installing mise via Homebrew"
        brew install mise
    else
        cat >&2 <<'EOF'
mise is required, but it was not found.

Install mise with a trusted package manager, or follow:
  https://mise.jdx.dev/installing-mise.html

Then rerun:
  bash ./scripts/unix-setup.sh
EOF
        exit 1
    fi
else
    step "mise already installed at $MISE_BIN"
fi

MISE_BIN="$(find_mise || true)"
if [ -z "$MISE_BIN" ]; then
    echo "mise was installed, but the setup script could not find it." >&2
    exit 1
fi

# --- 4. Activate mise in current shell + persist in rc file -------------------
# Script runs under bash, so use bash activation here regardless of $SHELL.
step "Activating mise in current session"
eval "$("$MISE_BIN" activate bash)"

touch "$RC_FILE"
if ! grep -q "mise activate" "$RC_FILE"; then
    step "Adding mise activation to $RC_FILE"
    printf '\n%s\n' "$ACTIVATE_CMD" >> "$RC_FILE"
else
    step "$RC_FILE already activates mise"
fi

# --- 5. Trust and install project tools ---------------------------------------
step "mise trust"
"$MISE_BIN" trust

step "mise install (node, bun, gh, prek, supabase, task)"
"$MISE_BIN" install

# --- 6. Project setup ----------------------------------------------------------
step "Running task setup"
task setup

# --- 7. prek hooks -------------------------------------------------------------
if [ "$SKIP_HOOKS" != "1" ]; then
    step "Running task hooks:install"
    task hooks:install
fi

printf '\n\033[1;32mSetup complete.\033[0m\n'
printf '\033[1;33mOpen a new shell (so mise activation loads) and run:\033[0m\n'
printf '\033[1;33m  task dev\033[0m\n'
