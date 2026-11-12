ANSIBLE_PLAYBOOK ?= ansible-playbook
CLAB ?= sudo containerlab
TOPOLOGY := digital_twin/DIGITAL_TWIN-topology.clab.yml

.PHONY: help setup build twin deploy inspect destroy

help:
	@echo 'make build    Generate regular EOS configs and documentation offline'
	@echo 'make twin     Generate Containerlab topology, startup configs, and docs offline'
	@echo 'make deploy   Launch the generated topology on a Linux Containerlab host'
	@echo 'make inspect  Show running lab nodes'
	@echo 'make destroy  Stop and remove the lab'

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
