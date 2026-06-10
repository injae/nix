{ pkgs, ... }:
{
  home.packages = with pkgs; [
    openssh
  ];

  programs.ssh = {
    enable = true;
    #addKeysToAgent = "yes";
    enableDefaultConfig = false;
    settings = {
      "*" = {
        ForwardAgent = false;
        AddKeysToAgent = "yes";
        Compression = false;
        ServerAliveInterval = 0;
        ServerAliveCountMax = 3;
        HashKnownHosts = false;
        UserKnownHostsFile = "~/.ssh/known_hosts";
        ControlMaster = "no";
        ControlPath = "~/.ssh/master-%r@%n:%p";
        ControlPersist = "no";
      };
      "github.com/injae" = {
        HostName = "github.com";
        IdentitiesOnly = true;
        IdentityFile = "/Users/nieel/.ssh/id_github";
      };
      "linux-builder" = {
        User = "builder";
        HostName = "localhost";
        #hostKeyAlias = "linux-builder";
        IdentityFile = "/etc/nix/builder_ed25519";
        Port = 31022;
      };
    };
  };
}
