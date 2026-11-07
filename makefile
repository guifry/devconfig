# Detect OS and architecture
UNAME := $(shell uname)
ARCH := $(shell uname -m)

# Select home-manager config based on platform
ifeq ($(UNAME),Darwin)
    ifeq ($(ARCH),arm64)
        CONFIG := darwin-arm64
    else
        CONFIG := darwin-x86
    endif
else
    ifeq ($(ARCH),aarch64)
        CONFIG := linux-arm64
    else
        CONFIG := linux-x86
    endif
endif

.PHONY: setup setup-light setup-full setup-server switch update clean doctor

CONFIG_SERVER := $(CONFIG)-server

setup: setup-light

setup-light:
	@./scripts/backup-existing.sh
	nix run home-manager -- switch --impure --flake .#$(CONFIG)
	./scripts/aliases-setup.sh
	@echo ""
	@echo "Installing Claude Code..."
	@command -v claude >/dev/null 2>&1 || curl -fsSL https://claude.ai/install.sh | sh
	@echo ""
	@echo "Light setup complete. Restart your shell or run: source ~/.zshrc"

setup-full: setup-light
	./scripts/ssh-setup.sh
	./scripts/python-setup.sh
	@echo ""
	@echo "Full setup complete."

setup-server:
	@if [ "$(UNAME)" = "Darwin" ]; then echo "Server mode is Linux-only."; exit 1; fi
	@./scripts/backup-existing.sh
	DEVCONFIG_MODE=server nix run home-manager -- switch --impure --flake .#$(CONFIG_SERVER)
	DEVCONFIG_MODE=server ALIAS_CATEGORIES="1 2 4" ./scripts/aliases-setup.sh
	@echo ""
	@echo "Installing Claude Code..."
	@command -v claude >/dev/null 2>&1 || curl -fsSL https://claude.ai/install.sh | bash
	@if command -v npm >/dev/null 2>&1; then npm uninstall -g --prefix "$$HOME/.local" opencode-ai >/dev/null 2>&1 || true; npm install -g --prefix "$$HOME/.local" @opencode/cli @openai/codex; elif [ -x "$$HOME/.nix-profile/bin/npm" ]; then "$$HOME/.nix-profile/bin/npm" uninstall -g --prefix "$$HOME/.local" opencode-ai >/dev/null 2>&1 || true; "$$HOME/.nix-profile/bin/npm" install -g --prefix "$$HOME/.local" @opencode/cli @openai/codex; fi
	@echo ""
	@./scripts/python-setup.sh
	@./scripts/git-identity-setup
	@./scripts/devconfig-cli.sh mise-setup
	@./scripts/server-provision.sh || echo "Warning: server provisioning incomplete"
	@echo ""
	@echo "Server setup complete. SSH wizard and nvim LSP setup skipped."

switch:
	nix run home-manager -- switch --impure --flake .#$(CONFIG)

update:
	nix flake update
	nix run home-manager -- switch --impure --flake .#$(CONFIG)

clean:
	nix-collect-garbage -d

doctor:
	@./scripts/doctor.sh
