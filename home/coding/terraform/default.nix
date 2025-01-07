{ pkgs, ... }:
{
  home.packages = with pkgs; [
    terraform-ls
    tflint
    terraform
  ];
}
