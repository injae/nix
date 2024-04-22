{ pkgs, ... }:
{
  home. packages = with pkgs; [
    terraform-lsp
    tflint
    terraform
  ];
}
