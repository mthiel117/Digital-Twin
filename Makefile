PYTHON ?= python3
ANSIBLE_PLAYBOOK ?= ansible-playbook
ANSIBLE_GALAXY ?= ansible-galaxy
CLAB ?= sudo containerlab
TOPOLOGY := digital_twin/DIGITAL_TWIN-topology.clab.yml

.PHONY: help setup build twin deploy inspect destroy

help:
	@echo 'make setup    Install dependencies in the container and ./collections (optional)'
	@echo 'make build    Generate regular EOS configs and documentation offline'
	@echo 'make twin     Generate Containerlab topology, startup configs, and docs offline'
	@echo 'make deploy   Launch the generated topology on a Linux Containerlab host'
	@echo 'make inspect  Show running lab nodes'
	@echo 'make destroy  Stop and remove the lab'

setup:
	$(PYTHON) -m pip install -r requirements.txt
	$(ANSIBLE_GALAXY) collection install -r requirements.yml -p ./collections

build:
	$(ANSIBLE_PLAYBOOK) build.yml

twin:
	$(ANSIBLE_PLAYBOOK) build-digital-twin.yml

deploy:
	@test -f "$(TOPOLOGY)" || (echo 'Run make twin first.'; exit 1)
	$(CLAB) deploy --topo "$(TOPOLOGY)"

inspect:
	$(CLAB) inspect --topo "$(TOPOLOGY)"

destroy:
	$(CLAB) destroy --topo "$(TOPOLOGY)" --cleanup
