{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # docker
    docker
    docker-buildx
    docker-compose
    docker-credential-helpers
    dive

    regctl

    # k8s
    kubectl
    krew
    k9s
    kustomize
    kubernetes-helm
    kubebuilder
    argocd

    ngrok

    stern
  ];
}
