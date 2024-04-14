{ ... }:
let
  name = "nieel";
in
{
  myself = name;
  users = {
    nieel = {
      name = "injae";
      email = "8687lee@gmail.com";
      sshKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJZek4oGRvG6SH4hW+hGF1lFz3czkh9PUExFVMaDU/IK 8687lee@gmail.com"
      ];
    };
  };
}
# for age..
