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

.PHONY: setup setup-light setup-full switch update clean doctor

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

switch:
	home-manager switch --impure --flake .#$(CONFIG)

update:
	nix flake update
	home-manager switch --impure --flake .#$(CONFIG)

clean:
	nix-collect-garbage -d

doctor:
	@./scripts/doctor.sh
