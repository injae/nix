{ pkgs, ... }:
{
  home.packages = with pkgs; [
    openssh
  ];

  programs.ssh = {
    enable = true;
    #addKeysToAgent = "yes";
    enableDefaultConfig = false;
    matchBlocks = {
      "*" = {
        forwardAgent = false;
        addKeysToAgent = "yes";
        compression = false;
        serverAliveInterval = 0;
        serverAliveCountMax = 3;
        hashKnownHosts = false;
        userKnownHostsFile = "~/.ssh/known_hosts";
        controlMaster = "no";
        controlPath = "~/.ssh/master-%r@%n:%p";
        controlPersist = "no";
      };
      "github.com/injae" = {
        hostname = "github.com";
        identitiesOnly = true;
        identityFile = "/Users/nieel/.ssh/id_github";
      };
      "linux-builder" = {
        user = "builder";
        hostname = "localhost";
        #hostKeyAlias = "linux-builder";
        identityFile = "/etc/nix/builder_ed25519";
        port = 31022;
      };
    };
  };
}
