# Secrets with Nix

## Add Secrets and PubKey
```shell
mkdir -p ~/.config/sops/age
ssh-to-age -private-key -i ~/.ssh/id_ed25519 > ~/.config/sops/age/keys.txt
age-keygen -y ~/.config/sops/age/keys.txt
```
