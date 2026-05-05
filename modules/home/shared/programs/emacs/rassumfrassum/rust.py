import asyncio
from pathlib import Path

from rassumfrassum.frassum import LspLogic, Server, DirectResponse
from rassumfrassum.json import JSON
from rassumfrassum.util import dmerge

initialize_method = "initialize"
initialization_options = "initializationOptions"

class RustLogic(LspLogic):
    async def on_client_request(self, method: str, params: JSON, servers: list[Server]) -> list[Server] | DirectResponse:
        if method == initialize_method:
            params[initialization_options] = dmerge(params.get(initialization_options, {}), {
                "check": { "command": "clippy" },
                "procMacro": { "enable": True },
                "diagnostics": {
                    "disabled": ["unresolved-import"],
                },
                "inlayHint": {
                    "parameterHints": {"enable": False},
                    "typeHints": {"enable": False},
                    "chainingHints": {"enable": False},
                },
            })
        return await super().on_client_request(method, params, servers)

def servers():
    return [
        ['rust-analyzer']
    ]

def logic_class():
    return RustLogic
