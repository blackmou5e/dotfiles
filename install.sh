#!/usr/bin/env bash
set -euo pipefail

# macOS bootstrap for this dotfiles repository.
# Installs Homebrew first, then the tools referenced by the configs here.

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() {
  printf '\n==> %s\n' "$*"
}

warn() {
  printf '\nWARN: %s\n' "$*" >&2
}

append_once() {
  local file="$1"
  local line="$2"
  local label="$3"

  mkdir -p "$(dirname "$file")"
  touch "$file"

  if ! grep -Fqx "$line" "$file"; then
    {
      printf '\n# %s\n' "$label"
      printf '%s\n' "$line"
    } >>"$file"
  fi
}

ensure_macos() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    printf 'This installer targets macOS only.\n' >&2
    exit 1
  fi
}

ensure_homebrew() {
  local brew_bin=""

  if command -v brew >/dev/null 2>&1; then
    brew_bin="$(command -v brew)"
  elif [[ -x /opt/homebrew/bin/brew ]]; then
    brew_bin="/opt/homebrew/bin/brew"
  elif [[ -x /usr/local/bin/brew ]]; then
    brew_bin="/usr/local/bin/brew"
  fi

  if [[ -z "$brew_bin" ]]; then
    log "Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  else
    log "Homebrew already installed at $brew_bin"
  fi

  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  elif command -v brew >/dev/null 2>&1; then
    eval "$(brew shellenv)"
  else
    printf 'Homebrew installation finished, but brew was not found in a standard location.\n' >&2
    exit 1
  fi

  append_once "$HOME/.zprofile" "eval \"\$($(brew --prefix)/bin/brew shellenv)\"" "Homebrew"
}

brew_add_taps() {
    local tap

    for tap in "$@"; do
        if brew tap-info "$tap" >/dev/null 2>&1; then
            log "$tap already added"
        else
            log "Adding tap $tap"
            brew tap "$tap"
        fi
    done
}


brew_install_formulae() {
  local formula

  for formula in "$@"; do
    if brew list --formula "$formula" >/dev/null 2>&1; then
      log "$formula already installed"
    else
      log "Installing $formula"
      brew install "$formula"
    fi
  done
}

brew_install_casks() {
  local cask app_path

  for cask in "$@"; do
    if brew list --cask "$cask" >/dev/null 2>&1; then
      log "$cask already installed"
      continue
    fi

    app_path=""
    case "$cask" in
      ghostty) app_path="/Applications/Ghostty.app" ;;
      google-chrome) app_path="/Applications/Google Chrome.app" ;;
    esac

    if [[ -n "$app_path" && -d "$app_path" ]]; then
      log "$cask already present at $app_path"
      continue
    fi

    log "Installing cask $cask"
    brew install --cask "$cask"
  done
}

install_neovim() {
  local bob_nvim_bin="$HOME/.local/share/bob/nvim-bin"
  local bob_path_line="export PATH=\"\$HOME/.local/share/bob/nvim-bin:\$PATH\""

  if brew list --formula bob >/dev/null 2>&1; then
    log "bob already installed"
  else
    log "Installing bob"
    brew install bob
  fi

  # Put bob-managed Neovim before any Homebrew/system nvim.
  export PATH="$bob_nvim_bin:$PATH"
  append_once "$HOME/.zprofile" "$bob_path_line" "bob (Neovim)"
  append_once "$HOME/.zshrc" "$bob_path_line" "bob (Neovim)"

  # bob may leave a read-only nvim proxy in nvim-bin; remove it before switching
  # versions so `bob use stable` can recreate it instead of failing to copy over it.
  if [[ -e "$bob_nvim_bin/nvim" || -L "$bob_nvim_bin/nvim" ]]; then
    chmod u+w "$bob_nvim_bin/nvim" 2>/dev/null || true
    rm -f "$bob_nvim_bin/nvim"
  fi

  log "Installing and selecting Neovim stable via bob"
  bob use stable
}

install_brew_tools() {
  log "Updating Homebrew"
  brew_add_taps \
      anomalyco/tap \
      hashicorp/tap

  brew update

  install_neovim

  brew_install_formulae \
    ansible \
    awscli \
    d2 \
    deno \
    diffnav \
    gh \
    git \
    gmp \
    go \
    gopls \
    hadolint \
    helm \
    helm-ls \
    jq \
    just \
    kubernetes-cli \
    lazydocker \
    lazygit \
    libyaml \
    lua-language-server \
    mise \
    mole \
    node \
    opencode \
    openssl@3 \
    opentofu \
    pkg-config \
    python \
    readline \
    ripgrep \
    ruby-build \
    ruff \
    rust \
    rust-analyzer \
    rustup \
    shellcheck \
    socat \
    sqlite \
    staticcheck \
    stern \
    tinymist \
    tmux \
    typescript \
    typescript-language-server \
    typst \
    uv \
    yaml-language-server \
    yt-dlp \
    zoxide

  brew_install_casks \
    docker-desktop \
    font-hurmit-nerd-font \
    ghostty \
    google-chrome \
    obsidian \
    raycast \
    spotify \
    zoom
}

install_gh_extensions() {
  if ! command -v gh >/dev/null 2>&1; then
    warn "github-cli is not available; skipping gh extensions"
    return
  fi

  log "Installing gh dashboard extension"
  gh extension install dlvhdr/gh-dash

  log "Installing gh actions extension"
  gh extension install dlvhdr/gh-enhance
}

install_npm_tools() {
  if ! command -v npm >/dev/null 2>&1; then
    warn "npm is not available; skipping npm-based tools"
    return
  fi

  log "Installing Pi coding agent"
  npm install -g @earendil-works/pi-coding-agent
}

link_dotfiles() {
  log "Linking dotfiles"
  make -C "$DOTFILES_DIR" link
}

install_mise_tools() {
  if ! command -v mise >/dev/null 2>&1; then
    warn "mise is not available; skipping mise-managed tools"
    return
  fi

  append_once "$HOME/.zshrc" "eval \"\$(mise activate zsh)\"" "mise"

  log "Installing mise-managed tools from mise/config.toml"
  mise install -y
}

setup_pi_config() {
  local pi_dir="$HOME/.pi/agent"
  local example_settings="$DOTFILES_DIR/pi/agent/example_settings.json"

  mkdir -p "$pi_dir"

  if [[ ! -e "$pi_dir/settings.json" && -f "$example_settings" ]]; then
    log "Creating Pi settings from example_settings.json"
    cp "$example_settings" "$pi_dir/settings.json"
  fi
}

main() {
  ensure_macos

  # Homebrew must be installed before any other tool.
  ensure_homebrew

  install_brew_tools
  install_npm_tools
  install_gh_extensions
  link_dotfiles
  install_mise_tools
  setup_pi_config

  log "Installation complete. Restart your shell or run: source ~/.zprofile && source ~/.zshrc"
}

main "$@"
