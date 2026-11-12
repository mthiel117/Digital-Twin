# Add a Containerlab digital twin to an existing AVD repository

This standalone recipe targets **AVD 6.5.0**. It extracts the reusable pieces
from this repository: the twin overlay, build playbook, image selection,
Makefile targets, and deployment commands. Keep your destination repository's
existing inventory, node definitions, interfaces, VLANs, and network services.
The six-switch L2LS topology (one spine MLAG pair and two leaf MLAG pairs) is
not required by this workflow. The destination inventory defines its own nodes
and peer links; rebuild its twin after changing those inputs.

## 1. Use matching AVD dependencies in your dev container

Use PyAVD **6.5.0** and the `arista.avd` Ansible collection **6.5.0** together.
For the same dev container as this repository, use this image in your existing
`.devcontainer/devcontainer.json`, preserving its other settings:

```json
{
  "image": "ghcr.io/aristanetworks/avd/universal:python3.13-avd-v6.5.0"
}
```

Rebuild the dev container after changing its image. The commands below use the
container's installed `ansible-playbook`; no virtual environment is needed.
Your existing `ansible.cfg` must discover the AVD collection and inventory.

## 2. Add a lab-only variable file

Create **`digital-twin-vars.yml`** next to the new playbook in the destination
repository. The playbook loads it only for twin builds, so these lab credentials
do not have to be added to your production group variables.

```yaml
---
digital_twin:
  environment: containerlab
  # Required by the AVD 6.5 schema, including for Containerlab.
  fabric: {}
  use_default_interfaces_of_digital_twin_platform: true

# Repository helper consumed by the final playbook task, not an AVD key.
_containerlab_image: arista/ceos:latest

mgmt_interface_settings:
  interface: Management1
  vrf: MGMT

# Lab account carried over from this repository.
ansible_user: admin
ansible_password: ""
aaa_settings:
  local_users:
    - name: admin
      privilege: 15
      role: network-admin
      no_password: true
  authentication:
    policies:
      local:
        allow_nopassword: true
  authorization:
    exec:
      default: local
```

The `aaa_settings` overlay replaces inventory-level AAA settings for this play;
it deliberately selects the passwordless lab account. Remove that section and
the `ansible_user` / `ansible_password` entries if you want to retain the
destination fabric's authentication instead. Do not combine `no_password: true`
with a password hash for the same user.

If you use a management VRF other than `MGMT`, adjust the overlay to match.
No management addresses are copied from this example. Retain each destination
node's static `mgmt_ip` and the matching `mgmt_gateway` in its existing model.

## 3. Add the twin build playbook

Create **`build-digital-twin.yml`** next to `digital-twin-vars.yml`:

```yaml
---
- name: Build Containerlab digital twin artifacts
  hosts: "{{ twin_fabric_group | default('FABRIC') }}"
  connection: local
  gather_facts: false
  vars_files:
    - digital-twin-vars.yml
  vars:
    ansible_python_interpreter: "{{ ansible_playbook_python }}"
    avd_digital_twin_mode: true

    # Anchor generated artifacts beside this playbook, even when the
    # destination inventory is in a subdirectory.
    root_dir: "{{ playbook_dir }}"
    output_dir_name: digital_twin/intended
    output_dir: "{{ root_dir }}/{{ output_dir_name }}"
    documentation_dir_name: digital_twin/documentation
    documentation_dir: "{{ root_dir }}/{{ documentation_dir_name }}"
    structured_dir: "{{ output_dir }}/structured_configs"
    eos_config_dir: "{{ output_dir }}/configs"
    _containerlab_topology_file: "{{ root_dir }}/digital_twin/{{ fabric_name }}-topology.clab.yml"

  tasks:
    - name: Generate structured configurations and Containerlab topology
      ansible.builtin.import_role:
        name: arista.avd.eos_designs

    - name: Generate EOS startup configurations and device documentation
      ansible.builtin.import_role:
        name: arista.avd.eos_cli_config_gen

    - name: Apply the selected cEOS image to the generated topology
      ansible.builtin.copy:
        dest: "{{ _containerlab_topology_file }}"
        mode: "0644"
        content: >-
          {{
            lookup('ansible.builtin.file', _containerlab_topology_file)
            | from_yaml
            | combine(
                {'topology': {'kinds': {'arista_ceos': {'image': _containerlab_image}}}},
                recursive=true
              )
            | to_nice_yaml(indent=2, sort_keys=false)
          }}
      delegate_to: localhost
      run_once: true
```

AVD 6.5 already defaults the generated image to `arista/ceos:latest`. The final
task keeps the image configurable through `_containerlab_image`; omit that
task and helper variable if you always want AVD's default.

Select **one complete fabric** for each build. `fabric_name` must remain the
name of its existing inventory group, and all selected devices must agree on
it. Avoid limiting the build to individual switches. If your existing model
overrides other output paths such as `fabric_dir` or `devices_dir`, point those
under `digital_twin/documentation` for this play as well.

For example, if the inventory is `inventory/hosts.yml` and the existing
`fabric_name` and corresponding group are `DC1`:

```bash
ansible-playbook -i inventory/hosts.yml build-digital-twin.yml \
  -e twin_fabric_group=DC1
```

This creates `digital_twin/DC1-topology.clab.yml` beside the playbook. It does
not connect to switches or deploy containers.

## 4. Add optional Makefile targets

Merge this fragment into the destination Makefile, adapting target names if
they already exist. Recipe lines must start with a **tab**. Set `FABRIC_NAME`
to the existing model's `fabric_name`; `FABRIC_GROUP` selects the devices to
build and defaults to that same group.

```makefile
ANSIBLE_PLAYBOOK ?= ansible-playbook
CLAB ?= sudo containerlab
INVENTORY ?= inventory.yml
FABRIC_NAME ?= FABRIC
FABRIC_GROUP ?= $(FABRIC_NAME)
TOPOLOGY = digital_twin/$(FABRIC_NAME)-topology.clab.yml

.PHONY: twin deploy inspect destroy

twin:
	$(ANSIBLE_PLAYBOOK) -i "$(INVENTORY)" build-digital-twin.yml -e "twin_fabric_group=$(FABRIC_GROUP)"

deploy:
	@test -f "$(TOPOLOGY)" || (echo 'Run make twin first.'; exit 1)
	$(CLAB) deploy --topo "$(TOPOLOGY)"

inspect:
	$(CLAB) inspect --topo "$(TOPOLOGY)"

destroy:
	$(CLAB) destroy --topo "$(TOPOLOGY)" --cleanup
```

For the `DC1` example:

```bash
make twin INVENTORY=inventory/hosts.yml FABRIC_NAME=DC1
make deploy FABRIC_NAME=DC1
make inspect FABRIC_NAME=DC1
make destroy FABRIC_NAME=DC1
```

## 5. Prepare the runtime and deploy

Deploy on a Linux host with Docker, Containerlab, and a compatible cEOS-lab
image. Inspect the existing image or import your downloaded Arista archive:

```bash
sudo docker image inspect arista/ceos:latest
# Only if the image is missing, using your actual archive path:
sudo docker import /path/to/cEOS-lab.tar.xz arista/ceos:latest
```

You can build inside a dev container and copy the entire generated
`digital_twin/` directory to the Linux host. Keep the generated topology,
`interface_mapping.json`, and `intended/configs/` together. From its parent:

```bash
sudo containerlab deploy --topo digital_twin/DC1-topology.clab.yml
sudo containerlab inspect --topo digital_twin/DC1-topology.clab.yml
sudo docker exec -it YOUR_SWITCH_HOSTNAME Cli
```

Replace `DC1` and `YOUR_SWITCH_HOSTNAME` with names from your destination model.
The generated topology has `prefix: ''`, so container names match hostnames.
The lab login from the overlay is `admin` with no password.

Destroy the running lab before regenerating and redeploying changed configs:

```bash
sudo containerlab destroy --topo digital_twin/DC1-topology.clab.yml --cleanup
```

## AVD 6.5 requirements that matter when reusing this

- Containerlab generation is a PREVIEW feature. It models fabric switches and
  point-to-point fabric links; connected endpoints are not generated.
- Every fabric node needs a static IPv4 `mgmt_ip` in the **same subnet**.
  Missing addresses and `mgmt_ip: dhcp` are unsupported.
- Only out-of-band management on `Management1` is supported. Containerlab
  currently reuses the regular `mgmt_ip`; per-node `digital_twin.mgmt_ip` does
  not give this generator a separate management address.
- Management addresses therefore need isolation from production. The Docker
  management network is fixed to `custom_mgmt`; deploy one twin at a time on a
  host and check for subnet conflicts before deployment.
- Keep the output directory layout shown above. Generated startup-config paths
  are fixed to `intended/configs/<hostname>.cfg` relative to the topology file.
- AVD maps original platforms to their digital twin platforms. Review the
  destination fabric's `platform_settings` / `custom_platform_settings` and
  interface choices if its hardware needs different virtual settings.

Generated files can be ignored using these optional `.gitignore` entries:

```gitignore
digital_twin/intended/
digital_twin/documentation/
digital_twin/*-topology.clab.yml
digital_twin/interface_mapping.json
digital_twin/clab-*/
digital_twin/.clab-*/
```

## Version-matched references

- [AVD 6.5 Containerlab documentation](https://avd.arista.com/6.5/ansible_collections/arista/avd/roles/eos_designs/docs/data-models.html#containerlab-digital-twin)
- [Digital twin input schema](https://github.com/aristanetworks/avd/blob/v6.5.0/python-avd/pyavd/_eos_designs/schema/schema_fragments/digital_twin.schema.yml)
- [Containerlab generator implementation](https://github.com/aristanetworks/avd/blob/v6.5.0/python-avd/pyavd/get_fabric_documentation.py#L192)

Prepared from source at `v6.5.0`, commit
`6867159b26356ca5a03e267bf9f8db01ff862b14`. This extraction was reviewed
statically; no playbooks or containers were run.
