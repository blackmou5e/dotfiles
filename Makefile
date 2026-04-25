.PHONY: install link clean

DOTFILES_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
XDG_CONFIG := $(HOME)/.config

link = ln -sf $(DOTFILES_DIR)$(1) $(2)

# source:target pairs
DIRS := \
	ghostty:$(XDG_CONFIG)/ghostty \
	git/config:$(HOME)/.gitconfig \
	helix:$(XDG_CONFIG)/helix \
	mise:$(XDG_CONFIG)/mise \
	nvim_nightly:$(XDG_CONFIG)/nvim \
	tmux:$(XDG_CONFIG)/tmux \
	tofurc:$(HOME)/.tofurc

install: link
	@echo "Dotfiles installed successfully"

link:
	@$(foreach pair,$(DIRS),\
		$(eval src := $(word 1,$(subst :, ,$(pair))))\
		$(eval tgt := $(word 2,$(subst :, ,$(pair))))\
		$(call link,$(src),$(tgt)) &&) \
		echo "Linked all configs"

clean:
	@$(foreach pair,$(DIRS),\
		$(eval tgt := $(word 2,$(subst :, ,$(pair))))\
		rm -f $(tgt);) \
		echo "Cleaned all symlinks"