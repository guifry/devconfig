# Detect OS and architecture
UNAME := $(shell uname)
ARCH := $(shell uname -m)

# Select home-manager config based on platform
ifeq ($(UNAME),Darwin)
    ifeq ($(ARCH),arm64)
        CONFIG := guilhemforey@darwin
    else
        CONFIG := guilhemforey@darwin-x86
    endif
else
    CONFIG := guilhemforey@linux
endif

.PHONY: setup switch update clean

# First-time setup (bootstraps home-manager)
setup:
	nix run home-manager -- switch --flake .#$(CONFIG)

# Apply config changes (after home-manager installed)
switch:
	home-manager switch --flake .#$(CONFIG)

# Update flake inputs (nixpkgs, home-manager) and apply
update:
	nix flake update
	home-manager switch --flake .#$(CONFIG)

# Remove old generations, free disk space
clean:
	nix-collect-garbage -d
