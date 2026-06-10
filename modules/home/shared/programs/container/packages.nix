{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # docker
    docker
    docker-buildx
    docker-compose

    docker-language-server

    #docker-credential-helpers
    dive
    istioctl

    regctl

    # k8s
    kubectl
    krew
    k9s
    kustomize
    kubernetes-helm
    kubectl-explore
    kubebuilder
    argocd

    stern

    cloudflared
  ];
  programs.zsh.envExtra = ''
    export KUBECONFIG="$HOME/.kube/config"
    # krew
    export PATH="''${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
  '';
}
