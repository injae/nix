let
  m3-mac = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJZek4oGRvG6SH4hW+hGF1lFz3czkh9PUExFVMaDU/IK 8687 lee@gmail.com";
  all = [ m3-mac ];
in
{
  "spotify.age".publicKeys = all;
  "discord-client-id.age".publicKeys = all;
  "chatgpt-api-key.age".publicKeys = all;
}
