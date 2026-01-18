# Questionnaires

The questionnaires exist so that a brand new admin node can capture what it needs to operate, without hard-coding environment assumptions.

## Core questionnaire (implemented)

Stored in `generated_configs/homelab.env`.

- `PROXMOX_HOST`: Proxmox hostname/IP.
- `PROXMOX_PORT`: API port (default 8006).
- `PROXMOX_NODE`: default target node name.
- `LAN_CIDR`: your LAN CIDR (planning input for DHCP/DNS).
- `GATEWAY_IP`: MikroTik LAN gateway IP.
- `DNS_UPSTREAM`: upstream resolvers.
- `CATPPUCCIN_FLAVOUR`: latte|frappe|macchiato|mocha.
- `HL_EMOJI`: 1 or 0.

## Next questionnaires (planned)

These are intentionally not auto-assumed. They need your answers before we wire the service roles to real defaults.

- DHCP scope design (ranges, reservations, VLANs).
- DNS zone(s) and internal domain name.
- Active Directory choices (Samba AD vs Windows Server).
- Talos cluster size, node sizing, and storage model.
- UDMS options (which apps, storage paths, user/group IDs).
- Proxmox storage: where ISOs, templates, and VM disks should live.

