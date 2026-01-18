# Security and secrets

## Principles

- No sensitive info committed to git.
- Encrypted-at-rest secrets in repo using SOPS (recommended with age keys).
- Operational secrets stored in Vaultwarden.

## SOPS workflow (age)

1. Generate an age key (store securely):

   age-keygen -o ~/.config/sops/age/keys.txt

2. Export your public key:

   age-keygen -y ~/.config/sops/age/keys.txt

3. Add the public key to `.sops.yaml` under `age:`.

4. Create a secret file:

   sops secrets/example.yml

## Vaultwarden

Vaultwarden is ideal for day-to-day credential management and sharing.

- Example compose file: `docker/vaultwarden/compose.yml`.
- Recommendation: run behind a reverse proxy with TLS.

## Proxmox provider caveats

Some Proxmox API actions require a PAM account (for example, uploading certain file types via SFTP), so you may need to combine API token auth with a PAM account for specific operations.
