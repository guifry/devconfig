#####################
##      SETUP      ##
#####################

# Going to install all the configs and scripts on the machine
setup-machine: setup-configs setup-git-aliases setup-scripts setup-devconfig-cli

setup-configs:
	cp .bashrc ~/.bashrc
	cp .zshrc ~/.zshrc
	cp .vimrc ~/.vimrc

setup-git-aliases:
	./loadGitAliases.sh

setup-scripts:
	cp -r ./scripts ~/bin

setup-devconfig-cli:
	cd devconfig-cli && uv sync
	mkdir -p ~/.devconfig
	ln -sf $(PWD)/agent-guide-db ~/.devconfig/agent-guide-db
	ln -sf $(PWD)/scripts/devconfig ~/bin/devconfig

setup-clippy:
	cd clippy && uv sync
	mkdir -p ~/.clippy
	mkdir -p ~/bin
	ln -sf $(PWD)/clippy/.venv/bin/clippy ~/bin/clippy
	cp clippy/service/com.clippy.daemon.plist ~/Library/LaunchAgents/
	launchctl load ~/Library/LaunchAgents/com.clippy.daemon.plist 2>/dev/null || true
	@echo "Clippy installed and running."
	@echo "Grant Accessibility: System Preferences → Privacy → Accessibility"


######################
##      UPDATE      ##
######################

# Going to update everything at once
update-devconfig: update-configs update-scripts update-vscode-configs

update-configs:
	cp ~/.bashrc .bashrc
	cp ~/.zshrc .zshrc
	cp ~/.vimrc .vimrc

update-scripts:
	cp -r ~/bin/* ./scripts

update-vscode-configs:
	cp -r ~/.vscode/vscode/* ./vscode

update-agent-guide-db:
	@echo "Agent guide DB is symlinked, no update needed"


######################
##    WORKSPACES    ##
######################

setup-kpler:
	mkdir -p ~/kpler
	mkdir -p ~/bin
	ln -sf $(PWD)/workspaces/kpler/create-fullstack-wt.py ~/bin/create-fullstack-wt
	chmod +x ~/bin/create-fullstack-wt
	@echo "Kpler workspace setup complete. Run 'create-fullstack-wt' from anywhere."