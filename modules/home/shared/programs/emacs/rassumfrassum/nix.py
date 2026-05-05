from rassumfrassum.frassum import LspLogic, Server, DirectResponse
from rassumfrassum.json import JSON
from rassumfrassum.util import dmerge

initialize_method = "initialize"
initialization_options = "initializationOptions"

def get_nix_path(params: JSON) -> str:
    #return params.get("rootPath")
    return "/Users/nieel/nix"

def get_nix_host() -> str:
    return "nieel-m3"

class NixLogic(LspLogic):
    async def on_client_request(self, method: str, params: JSON, servers: list[Server]) -> list[Server] | DirectResponse:
        if method == initialize_method:
            root_path = get_nix_path(params)
            params[initialization_options] = dmerge(params.get(initialization_options, {}), {
                "nixpkgs": {"expr": "import <nixpkgs> { }"},
                "formatting": {"command": ["nixfmt"]},
                "options": {
                    "nixos": {
                        "expr": f'(builtins.getFlake "{root_path}").darwinConfigurations.{get_nix_host()}.options',
                    },
                    "home-manager": {
                        "expr": f'(builtins.getFlake "{root_path}").homeConfigurations.{get_nix_host()}.options',
                    },
                },
            })
        return await super().on_client_request(method, params, servers)

def servers():
    return [
        ['nixd']
    ]


def logic_class():
    return NixLogic
