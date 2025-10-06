{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # docker
    docker
    docker-buildx
    docker-compose
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
    kubebuilder
    argocd

    ngrok

    stern

    cloudflared
  ];
  programs.zsh.envExtra = ''
    export KUBECONFIG="$HOME/.kube/config:$HOME/.kube/embark:$HOME/.kube/home"

    # krew
    export PATH="''${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
  '';
}
