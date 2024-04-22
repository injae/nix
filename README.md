# Secrets with Nix

## Add Secrets and PubKey
```
cd ./home/programs/agenix/

# update ./home/programs/agenix/secrets.nix
agenix -e ${new_secert.age} # add new secret 
agenix -r                   # add new public key
```

```shell
mkdir -p ~/.config/sops/age
ssh-to-age -private-key -i ~/.ssh/id_ed25519 > ~/.config/sops/age/keys.txt
age-keygen -y ~/.config/sops/age/keys.txt
```
