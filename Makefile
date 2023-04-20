.DEFAULT_GOAL := help
include .env
export
.EXPORT_ALL_VARIABLES:
MAKE=make
##@ Manage

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
	if [ ! -d "../picachu-api-private" ] ; then git clone git@github.com:TourmalineCore/picachu-api-private.git --branch feature/test-push ; fi
	if [ ! -d "../picachu-ui" ] ; then git clone git@github.com:TourmalineCore/picachu-ui.git ; fi

real-update-repo: 
	cd ./picachu-api-private && git pull
	cd ./picachu-ui && git pull

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
	
.PHONY: help
help:
ifeq ($(OS),Windows_NT)
	@echo -e "$$(grep -hE '^\S+:.*##' $(MAKEFILE_LIST) | sed -e 's/:.*##\s*/:/' -e 's/^\(.\+\):\(.*\)/\\\e[34m\1\\\e[0m:\2/' | column -c2 -t -s :)"
else
	@echo "$$(grep -hE '^\S+:.*##' $(MAKEFILE_LIST) | sed -e 's/:.*##\s*/:/' -e 's/^\(.\+\):\(.*\)/\\\e[34m\1\\\e[0m:\2/' | column -c2 -t -s :)"
endif
