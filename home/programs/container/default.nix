{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # docker
    docker
    docker-buildx
    docker-compose
    dive

    # k8s
    kubectl
    krew
    k9s
    kustomize
    kubernetes-helm

    ngrok
  ];
}
