# Secrets

Store encrypted secrets here using SOPS.

Example:

1. Install sops.
2. Create an age key pair.
3. Update `.sops.yaml` with your age public key.
4. Create a file:

   sops --encrypt --in-place secrets/example.yml

Do not store unencrypted secrets in this repository.
