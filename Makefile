.DEFAULT_GOAL := help
include .env
export
.EXPORT_ALL_VARIABLES:
MAKE=make
##@ Manage

# curl -L -k -o hostctl_1.1.4_windows_64-bit.zip  https://github.com/guumaster/hostctl/releases/download/v1.1.4/hostctl_1.1.4_windows_64-bit.zip
# unzip hostctl_1.1.4_windows_64-bit.zip -d hostctl
# rm -rf hostctl

ifeq ($(MAKELEVEL), 0)
clone-repo: callback:=clone-repo
clone-repo: ssh-agent-auth

update-repo: callback:=update-repo
update-repo: ssh-agent-auth
else
clone-repo: pre-git-target real-clone-repo post-git-target ## cloning all repo
update-repo: pre-git-target real-update-repo post-git-target ## update cloned repos
endif

real-clone-repo:
	if [ ! -d "../picachu-api-private" ] ; then git clone git@github.com:TourmalineCore/picachu-api-private.git ; fi
	if [ ! -d "../picachu-ui" ] ; then git clone git@github.com:TourmalineCore/picachu-ui.git ; fi

real-update-repo: 
	cd ../picachu-api-private && git pull
	cd ../picachu-ui && git pull

pre-git-target: ssh-add-key

# for pid in $(ps -ef | awk '/ssh-agent/ {print $2}'); do kill -9 $pid; done
post-git-target:
# Remove all ssh-agent processes
#	bash -c "for pid in \$$(ps -ef | awk '/ssh-agent/ {print \$$2}'); do kill -9 \$$pid; done"
# Remove only our ssh-agent
	bash -c "kill -9 \$$SSH_AGENT_PID"

ssh-agent-auth: 
	bash -c "eval \$$(ssh-agent); for var in \$$(compgen -v); do export \$$var; done; $(MAKE) $(callback)"

ssh-add-key:
	echo $(SSH_AUTH_SOCK) 
	echo $(SSH_AGENT_PID)
	SSH_ASKPASS=./password-supplier.sh ssh-add -v $(SSH_KEY_PATH) <<< $(SSH_KEY_PASS)

install-dependency: ## install dependency
	choco install -f k3d --version=5.4.6 -y \
	&& choco install -f kubernetes-cli --version=1.26.0 -y \
	&& choco install -f kubernetes-helm --version=3.11.2 -y \
	&& choco install -f kubernetes-helmfile --version=0.144.0 -y \
	&& mkdir -p $$(helm env | awk -F"[\"]+" '/HELM_PLUGINS=/{print $$2}') \
	&& curl -L -k -o helm-diff-windows.tgz https://github.com/databus23/helm-diff/releases/download/v3.1.3/helm-diff-windows.tgz \
	&& tar -xvzf helm-diff-windows.tgz \
	&& cp -r diff $$(helm env | awk -F"[\"]+" '/HELM_PLUGINS=/{print $$2}')/ \
	&& rm -r diff \
	&& rm helm-diff-windows.tgz \
	&& curl -L -k -o hostctl_1.1.4_windows_64-bit.zip  https://github.com/guumaster/hostctl/releases/download/v1.1.4/hostctl_1.1.4_windows_64-bit.zip \
	&& unzip hostctl_1.1.4_windows_64-bit.zip -d hostctl \
	&& rm -r hostctl_1.1.4_windows_64-bit.zip

uninstall-dependency: ## uninstall dependency
	choco uninstall k3d \
	&& choco uninstall kubernetes-helmfile \
	&& choco uninstall kubernetes-cli \
	&& rm -r $$(helm env | awk -F"[\"]+" '/HELM_PLUGINS=/{print $$2}') \
	&& choco uninstall kubernetes-helm \
	&& rm -rf hostctl

create-cluster: ## create cluster `picachu-local` inside docker
	MSYS_NO_PATHCONV=1 cmd /c self-elevating.bat hostctl/hostctl.exe add domains picachu picachu.local.tourmalinecore.internal s3.picachu.local.tourmalinecore.internal s3-console.picachu.local.tourmalinecore.internal
	k3d cluster create picachu-local --agents 1 --k3s-arg "--disable=traefik@server:0" --port "80:30080@loadbalancer" --port "443:30443@loadbalancer" --port "30100:30100@loadbalancer"
	kubectl create namespace local
	kubectl config set-context --current --namespace=local

delete-cluster: ## delete cluster `picachu-local` from docker
	MSYS_NO_PATHCONV=1 cmd /c self-elevating.bat hostctl/hostctl.exe remove picachu
	k3d cluster delete picachu-local

add-bitnami-repo:
	helm repo add bitnami https://charts.bitnami.com/bitnami
	helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

local-deploy: add-bitnami-repo ## deploy all application inside k3s cluster
	helmfile --environment local -f deploy/helmfile.yaml apply

cleanup-local-deploy: ## cleanup k3s deployment
	helmfile --environment local -f deploy/helmfile.yaml destroy

.PHONY: help
help:
ifeq ($(OS),Windows_NT)
	@echo -e "$$(grep -hE '^\S+:.*##' $(MAKEFILE_LIST) | sed -e 's/:.*##\s*/:/' -e 's/^\(.\+\):\(.*\)/\\\e[34m\1\\\e[0m:\2/' | column -c2 -t -s :)"
else
	@echo "$$(grep -hE '^\S+:.*##' $(MAKEFILE_LIST) | sed -e 's/:.*##\s*/:/' -e 's/^\(.\+\):\(.*\)/\\\e[34m\1\\\e[0m:\2/' | column -c2 -t -s :)"
endif
