# Nix-WSL + Nix-Darwin + Emacs Configuration
- [emacs configuration](./home/programs/emacs/config)

# Add Secrets and PubKey
```shell
mkdir -p ~/.config/sops/age
ssh-to-age -private-key -i ~/.ssh/id_ed25519 > ~/.config/sops/age/keys.txt
age-keygen -y ~/.config/sops/age/keys.txt
sops updatekeys home/programs/sops/secrets/secrets.yaml
```

