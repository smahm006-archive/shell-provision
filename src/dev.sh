# setup default virtualenv
dev_python() {
	python3 -m venv $WORKSTATION/architecture/.pyvenv_default
	source $WORKSTATION/architecture/.pyvenv_default/bin/activate
	pip install --upgrade pip
	pip install black flake8 pyright
}

dev_nodejs() {
	sudo apt-get update
	sudo apt-get -y install nodejs
	npm config set prefix "${XDG_DATA_HOME}/npm"
	npm i -g bash-language-server
	npm i -g yaml-language-server
	npm i -g vls
}

dev_go() {
	export GOROOT=$WORKSTATION/architecture/toolchains/go
	export PATH=$PATH:$GOROOT/bin
	# find latest go version
	go_latest=$(
		wget --connect-timeout 5 -qO- https://go.dev/dl/ |
			grep -v -E 'go[0-9\.]+(beta|rc)' |
			grep -E -o 'go[0-9\.]+' |
			grep -E -o '[0-9]\.[0-9]+(\.[0-9]+)?' |
			sort -V | uniq |
			tail -1
	)

	# find current go version
	go_current=$(go version | grep -Po '\d+\.\d+\.\d+' || true)

	# install latest go if not latest
	if ! [ $(version $go_current) -ge $(version $go_latest) ]; then
		rm -rf $WORKSTATION/architecture/toolchains/go
		wget https://go.dev/dl/go${go_latest}.linux-amd64.tar.gz -P $WORKSTATION/architecture/toolchains/
		cd $WORKSTATION/architecture/toolchains
		tar -xf go*.tar.gz
		rm go*.tar.gz
	fi

	# install go language server
	go install golang.org/x/tools/gopls@latest
}

dev_rust() {
	export CARGO_HOME=$WORKSTATION/architecture/toolchains/rust/.cargo
	export RUSTUP_HOME=$WORKSTATION/architecture/toolchains/rust/.rustup
	export PATH=$PATH:$CARGO_HOME/bin
	# update rust or install if absent
	if ! rustup --version; then
		# install latest rust
		curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

		# setup rustup
		rustup override set stable
		rustup update stable
	else
		rustup update stable
	fi

}

dev_docker() {
    cd /tmp
    curl -fsSL https://get.docker.com -o install-docker.sh
    if sh install-docker.sh --dry-run; then
        sudo sh install-docker.sh
        sudo groupadd docker
        sudo usermod -aG docker $USER
    else
        error "Docker not installed"
    fi
}

dev_vagrant() {
	# set up vagrant apt repository
	curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --yes --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
	sudo tee /etc/apt/sources.list.d/docker.list >/dev/null <<EOF
deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $latest_stable_debian main
EOF
	sudo apt-get update

	# install vagrant
	sudo apt install -y vagrant
}

if [ $# -gt 0 ]; then
	dev_$1 $@
else
	for cmd in $(function_list_parser dev); do
		dev_$cmd
	done
fi
