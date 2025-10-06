{ writeShellApplication, cloudflared }:
writeShellApplication {
  name = "cloudflare-k8s-auth";
  runtimeInputs = [ cloudflared ];
  meta.description = ''
    cloudflared tunnel k8s client-go authentication
  '';
  text = ''
    endpoint=$1
    echo '{
        "apiVersion": "client.authentication.k8s.io/v1beta1",
        "kind": "ExecCredential",
        "status": {
            "token": "'"$(${cloudflared}/bin/cloudflared access token "$endpoint")"'"
        }
    }'
  '';
}
