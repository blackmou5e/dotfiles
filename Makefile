.PHONY: install link clean

DOTFILES_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
XDG_CONFIG := $(HOME)/.config
BACKUP_SUFFIX := backup.$(shell date +%Y%m%d%H%M%S)

# source:target pairs
DIRS := \
	ghostty:$(XDG_CONFIG)/ghostty \
	git/config:$(HOME)/.gitconfig \
	mise:$(XDG_CONFIG)/mise \
	nvim:$(XDG_CONFIG)/nvim \
	pi/agent:$(HOME)/.pi/agent \
	tmux:$(XDG_CONFIG)/tmux \
	tofurc:$(HOME)/.tofurc

install:
	@bash "$(DOTFILES_DIR)install.sh"

link:
	@set -e; \
	for pair in $(DIRS); do \
		src="$${pair%%:*}"; \
		tgt="$${pair#*:}"; \
		expected="$(DOTFILES_DIR)$$src"; \
		if [ ! -e "$$expected" ] && [ ! -L "$$expected" ]; then \
			echo "Missing source: $$expected" >&2; \
			exit 1; \
		fi; \
		mkdir -p "$$(dirname "$$tgt")"; \
		if [ -L "$$tgt" ]; then \
			current="$$(readlink "$$tgt" 2>/dev/null || true)"; \
			if [ "$$current" = "$$expected" ]; then \
				echo "Already linked $$tgt"; \
				continue; \
			fi; \
			backup="$$tgt.$(BACKUP_SUFFIX)"; \
			echo "Backing up $$tgt to $$backup"; \
			mv "$$tgt" "$$backup"; \
		elif [ -e "$$tgt" ]; then \
			backup="$$tgt.$(BACKUP_SUFFIX)"; \
			echo "Backing up $$tgt to $$backup"; \
			mv "$$tgt" "$$backup"; \
		fi; \
		ln -s "$$expected" "$$tgt"; \
	done; \
	echo "Linked all configs"

clean:
	@set -e; \
	for pair in $(DIRS); do \
		src="$${pair%%:*}"; \
		tgt="$${pair#*:}"; \
		expected="$(DOTFILES_DIR)$$src"; \
		if [ -L "$$tgt" ] && [ "$$(readlink "$$tgt" 2>/dev/null || true)" = "$$expected" ]; then \
			rm "$$tgt"; \
		elif [ -e "$$tgt" ] || [ -L "$$tgt" ]; then \
			echo "Skipping unmanaged path $$tgt"; \
		fi; \
	done; \
	echo "Cleaned managed symlinks"
