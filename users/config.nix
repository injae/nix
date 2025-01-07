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
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJZek4oGRvG6SH4hW+hGF1lFz3czkh9PUExFVMaDU/IK 8687lee@gmail.com" # m3
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKADaIM7+Kr262hzuv55OhzHXCwKfp0RcVHMOCXKJ0JW 8687lee@gmail.com" # desktop
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB1dYXyg79pPDlbDCzAdl7aZ911N/lAq43LHZVkXDOaw nieel@nexon.co.kr" # desktop-nexon
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICXRIYPMwaqeemqs5OaRtP3Q7YL0WnWCo42sSovORxZf 8687lee@gmail.com" # Android
      ];
    };
  };
}
# for age..
