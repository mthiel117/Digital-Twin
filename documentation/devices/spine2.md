# spine2

## Table of Contents

- [Management](#management)
  - [Management Interfaces](#management-interfaces)
  - [Management API HTTP](#management-api-http)
- [Authentication](#authentication)
  - [Local Users](#local-users)
  - [Enable Password](#enable-password)
  - [AAA Authentication](#aaa-authentication)
  - [AAA Authorization](#aaa-authorization)
- [MLAG](#mlag)
  - [MLAG Summary](#mlag-summary)
  - [MLAG Device Configuration](#mlag-device-configuration)
- [Spanning Tree](#spanning-tree)
  - [Spanning Tree Summary](#spanning-tree-summary)
  - [Spanning Tree Device Configuration](#spanning-tree-device-configuration)
- [Internal VLAN Allocation Policy](#internal-vlan-allocation-policy)
  - [Internal VLAN Allocation Policy Summary](#internal-vlan-allocation-policy-summary)
  - [Internal VLAN Allocation Policy Device Configuration](#internal-vlan-allocation-policy-device-configuration)
- [VLANs](#vlans)
  - [VLANs Summary](#vlans-summary)
  - [VLANs Device Configuration](#vlans-device-configuration)
- [Interfaces](#interfaces)
  - [Ethernet Interfaces](#ethernet-interfaces)
  - [Port-Channel Interfaces](#port-channel-interfaces)
  - [VLAN Interfaces](#vlan-interfaces)
- [Routing](#routing)
  - [Service Routing Protocols Model](#service-routing-protocols-model)
  - [IP Routing](#ip-routing)
  - [IPv6 Routing](#ipv6-routing)
  - [Static Routes](#static-routes)
- [Multicast](#multicast)
  - [IP IGMP Snooping](#ip-igmp-snooping)
- [VRF Instances](#vrf-instances)
  - [VRF Instances Summary](#vrf-instances-summary)
  - [VRF Instances Device Configuration](#vrf-instances-device-configuration)

## Management

### Management Interfaces

#### Management Interfaces Summary

##### IPv4

| Management Interface | Description | Type | VRF | IP Address | Gateway |
| -------------------- | ----------- | ---- | --- | ---------- | ------- |
| Management1 | OOB_MANAGEMENT | oob | MGMT | 172.30.30.12/24 | 172.30.30.1 |

##### IPv6

| Management Interface | Description | Type | VRF | IPv6 Address | IPv6 Gateway | ND RA Disabled | ND RA RX Accept | ND Managed Config Flag | ND Other Config Flag | ND Cache | ND RA DNS Servers |
| -------------------- | ----------- | ---- | --- | ------------ | ------------ | -------------- | --------------- | ---------------------- | -------------------- | -------- | ----------------- |
| Management1 | OOB_MANAGEMENT | oob | MGMT | - | - | - | - | - | - | - | - |

#### Management Interfaces Device Configuration

```eos
!
interface Management1
   description OOB_MANAGEMENT
   no shutdown
   vrf MGMT
   ip address 172.30.30.12/24
```

### Management API HTTP

#### Management API HTTP Summary

| HTTP | HTTPS | UNIX-Socket | Default Services | Session Timeout |
| ---- | ----- | ----------- | ---------------- | --------------- |
| False | True | - | - | 1440 minutes |

#### Management API VRF Access

| VRF Name | IPv4 ACL | IPv6 ACL |
| -------- | -------- | -------- |
| MGMT | - | - |

#### Management API HTTP Device Configuration

```eos
!
management api http-commands
   protocol https
   no shutdown
   !
   vrf MGMT
      no shutdown
```

## Authentication

### Local Users

#### Local Users Summary

| User | Privilege | Role | Disabled | Shell |
| ---- | --------- | ---- | -------- | ----- |
| admin | 15 | network-admin | False | - |

#### Local Users Device Configuration

```eos
!
username admin privilege 15 role network-admin nopassword
```

### Enable Password

Enable password has been disabled

### AAA Authentication

#### AAA Authentication Summary

| Type | Sub-type | User Stores |
| ---- | -------- | ---------- |

Policy local allow-nopassword-remote-login has been enabled.

#### AAA Authentication Device Configuration

```eos
aaa authentication policy local allow-nopassword-remote-login
!
```

### AAA Authorization

#### AAA Authorization Summary

| Type | User Stores |
| ---- | ----------- |
| Exec | local |

Authorization for configuration commands is disabled.

#### AAA Authorization Device Configuration

```eos
aaa authorization exec default local
!
```

## MLAG

### MLAG Summary

| Domain-id | Local-interface | Peer-address | Peer-link |
| --------- | --------------- | ------------ | --------- |
| SPINE_PAIR | Vlan4094 | 10.255.255.0 | Port-Channel1000 |

Dual primary detection is disabled.

### MLAG Device Configuration

```eos
!
mlag configuration
   domain-id SPINE_PAIR
   local-interface Vlan4094
   peer-address 10.255.255.0
   peer-link Port-Channel1000
   reload-delay mlag 300
   reload-delay non-mlag 330
```

## Spanning Tree

### Spanning Tree Summary

STP mode: **mstp**

#### MSTP Instance and Priority

| Instance(s) | Priority |
| -------- | -------- |
| 0 | 4096 |

#### Global Spanning-Tree Settings

- Spanning Tree disabled for VLANs: **4094**

### Spanning Tree Device Configuration

```eos
!
spanning-tree mode mstp
no spanning-tree vlan-id 4094
spanning-tree mst 0 priority 4096
```

## Internal VLAN Allocation Policy

### Internal VLAN Allocation Policy Summary

| Policy Allocation | Range Beginning | Range Ending |
| ----------------- | --------------- | ------------ |
| ascending | 1006 | 1199 |

### Internal VLAN Allocation Policy Device Configuration

```eos
!
vlan internal order ascending range 1006 1199
```

## VLANs

### VLANs Summary

| VLAN ID | Name | Trunk Groups |
| ------- | ---- | ------------ |
| 10 | USERS | - |
| 20 | SERVERS | - |
| 4094 | MLAG | MLAG |

### VLANs Device Configuration

```eos
!
vlan 10
   name USERS
!
vlan 20
   name SERVERS
!
vlan 4094
   name MLAG
   trunk group MLAG
```

## Interfaces

### Ethernet Interfaces

#### Ethernet Interfaces Summary

##### L2

| Interface | Description | Mode | VLANs | Native VLAN | Trunk Group | Channel-Group |
| --------- | ----------- | ---- | ----- | ----------- | ----------- | ------------- |
| Ethernet1 | L2_leaf1_Ethernet2 | *trunk | *10,20 | *- | *- | 1 |
| Ethernet2 | L2_leaf2_Ethernet2 | *trunk | *10,20 | *- | *- | 1 |
| Ethernet3 | L2_leaf3_Ethernet2 | *trunk | *10,20 | *- | *- | 3 |
| Ethernet4 | L2_leaf4_Ethernet2 | *trunk | *10,20 | *- | *- | 3 |
| Ethernet5 | MLAG_spine1_Ethernet5 | *trunk | *- | *- | *MLAG | 1000 |
| Ethernet6 | MLAG_spine1_Ethernet6 | *trunk | *- | *- | *MLAG | 1000 |

*Inherited from Port-Channel Interface

#### Ethernet Interfaces Device Configuration

```eos
!
interface Ethernet1
   description L2_leaf1_Ethernet2
   no shutdown
   channel-group 1 mode active
!
interface Ethernet2
   description L2_leaf2_Ethernet2
   no shutdown
   channel-group 1 mode active
!
interface Ethernet3
   description L2_leaf3_Ethernet2
   no shutdown
   channel-group 3 mode active
!
interface Ethernet4
   description L2_leaf4_Ethernet2
   no shutdown
   channel-group 3 mode active
!
interface Ethernet5
   description MLAG_spine1_Ethernet5
   no shutdown
   channel-group 1000 mode active
!
interface Ethernet6
   description MLAG_spine1_Ethernet6
   no shutdown
   channel-group 1000 mode active
```

### Port-Channel Interfaces

#### Port-Channel Interfaces Summary

##### L2

| Interface | Description | Mode | VLANs | Native VLAN | Trunk Group | LACP Fallback Timeout | LACP Fallback Mode | MLAG ID | EVPN ESI |
| --------- | ----------- | ---- | ----- | ----------- | ----------- | --------------------- | ------------------ | ------- | -------- |
| Port-Channel1 | L2_LEAF_PAIR_1_Port-Channel1 | trunk | 10,20 | - | - | - | - | 1 | - |
| Port-Channel3 | L2_LEAF_PAIR_2_Port-Channel1 | trunk | 10,20 | - | - | - | - | 3 | - |
| Port-Channel1000 | MLAG_spine1_Port-Channel1000 | trunk | - | - | MLAG | - | - | - | - |

#### Port-Channel Interfaces Device Configuration

```eos
!
interface Port-Channel1
   description L2_LEAF_PAIR_1_Port-Channel1
   no shutdown
   switchport trunk allowed vlan 10,20
   switchport mode trunk
   switchport
   mlag 1
!
interface Port-Channel3
   description L2_LEAF_PAIR_2_Port-Channel1
   no shutdown
   switchport trunk allowed vlan 10,20
   switchport mode trunk
   switchport
   mlag 3
!
interface Port-Channel1000
   description MLAG_spine1_Port-Channel1000
   no shutdown
   switchport mode trunk
   switchport trunk group MLAG
   switchport
```

### VLAN Interfaces

#### VLAN Interfaces Summary

| Interface | Description | VRF | MTU | Shutdown |
| --------- | ----------- | --- | --- | -------- |
| Vlan4094 | MLAG | default | 9214 | False |

##### IPv4

| Interface | VRF | IP Address | IP Address Virtual | IP Router Virtual Address | ACL In | ACL Out |
| --------- | --- | ---------- | ------------------ | ------------------------- | ------ | ------- |
| Vlan4094 | default | 10.255.255.1/31 | - | - | - | - |

#### VLAN Interfaces Device Configuration

```eos
!
interface Vlan4094
   description MLAG
   no shutdown
   mtu 9214
   no autostate
   ip address 10.255.255.1/31
```

## Routing

### Service Routing Protocols Model

Multi agent routing protocol model enabled

```eos
!
service routing protocols model multi-agent
```

### IP Routing

#### IP Routing Summary

| VRF | Routing Enabled |
| --- | --------------- |
| default | False |
| MGMT | False |

#### IP Routing Device Configuration

```eos
no ip routing vrf MGMT
```

### IPv6 Routing

#### IPv6 Routing Summary

| VRF | Routing Enabled |
| --- | --------------- |
| default | False |
| MGMT | False |

### Static Routes

#### Static Routes Summary

| VRF | Destination Prefix | Next Hop IP | Exit interface | Administrative Distance | Tag | Route Name | Metric |
| --- | ------------------ | ----------- | -------------- | ----------------------- | --- | ---------- | ------ |
| MGMT | 0.0.0.0/0 | 172.30.30.1 | - | 1 | - | - | - |

#### Static Routes Device Configuration

```eos
!
ip route vrf MGMT 0.0.0.0/0 172.30.30.1
```

## Multicast

### IP IGMP Snooping

#### IP IGMP Snooping Summary

| IGMP Snooping | Fast Leave | Interface Restart Query | Proxy | Restart Query Interval | Robustness Variable |
| ------------- | ---------- | ----------------------- | ----- | ---------------------- | ------------------- |
| Enabled | - | - | - | - | - |

#### IP IGMP Snooping Device Configuration

```eos
```

## VRF Instances

### VRF Instances Summary

| VRF Name | IP Routing |
| -------- | ---------- |
| MGMT | disabled |

### VRF Instances Device Configuration

```eos
!
vrf instance MGMT
```
