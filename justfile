hostname:
    uname -n

switch +ARGS="":
    nix run .#activate {{ARGS}}

update:
    nix flake update

make-key:
    ssh-keygen

init-key:
    mkdir -p ~/.config/sops/age
    ssh-to-age -private-key -i ~/.ssh/id_ed25519 > ~/.config/sops/age/keys.txt
    age-keygen -y ~/.config/sops/age/keys.txt

update-key:
    sops updatekeys home/programs/sops/secrets/secrets.yaml
