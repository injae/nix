{ pkgs, ... }:
{
  home.packages = with pkgs; [
    openssh
  ];

  programs.ssh = {
    enable = true;
    #addKeysToAgent = "yes";
    extraConfig = ''
      Host *
        ForwardAgent no
        AddKeysToAgent yes  
        Compression no
        ServerAliveInterval 0
        ServerAliveCountMax 3
        HashKnownHosts no
        UserKnownHostsFile ~/.ssh/known_hosts
        ControlMaster no
        ControlPath ~/.ssh/master-%r@%n:%p
        ControlPersist no

      Host github.com/injae
          Hostname github.com
          IdentitiesOnly yes
          IdentityFile /Users/nieel/.ssh/id_github

      Host linux-builder
        User builder
        Hostname localhost
        HostKeyAlias linux-builder
        IdentityFile /etc/nix/builder_ed25519
        Port 31022
    '';
  };
}
