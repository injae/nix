{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # docker
    docker
    docker-compose
    dive

    # k8s
    kubectl
    k9s
    kustomize

    ngrok
  ];
}
