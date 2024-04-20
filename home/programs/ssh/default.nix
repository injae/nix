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
  
      #Host github.com
      #    Hostname github.com
      #    IdentitiesOnly yes
      #    IdentityFile /Users/nieel/.ssh/id_github

      #HOST home-cluster-gateway
      #    HostName 172.30.1.53
      #    User ansible
      #    AddKeysToAgent yes  
      #    IdentityFile ~/.ssh/ansible-ssh-key  

      HOST home-cluster-gateway
          HostName node-1.netbird.cloud
          User ansible
          AddKeysToAgent yes  
          IdentityFile ~/.ssh/ansible-ssh-key  

      HOST home-cluster-node-1
          HostName 192.168.0.2
          User ansible
          ProxyJump home-cluster-gateway
          IdentityFile ~/.ssh/ansible-ssh-key  

      HOST home-cluster-node-2
          HostName 192.168.0.3
          User ansible
          ProxyJump home-cluster-gateway
          IdentityFile ~/.ssh/ansible-ssh-key  

      HOST home-cluster-node-3
          HostName 192.168.0.4
          User ansible
          ProxyJump home-cluster-gateway
          IdentityFile ~/.ssh/ansible-ssh-key  

      HOST home-cluster-node-4
          HostName 192.168.0.5
          User ansible
          ProxyJump home-cluster-gateway
          IdentityFile ~/.ssh/ansible-ssh-key  

      HOST home-cluster-nfs
          HostName 192.168.0.6
          User ansible
          ProxyJump home-cluster-gateway
          IdentityFile ~/.ssh/ansible-ssh-key  
    '';
  };
}
