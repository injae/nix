import asyncio
from pathlib import Path

from rassumfrassum.frassum import LspLogic, Server, DirectResponse
from rassumfrassum.json import JSON
from rassumfrassum.util import dmerge

initialize_method = "initialize"
initialization_options = "initializationOptions"

class GoLogic(LspLogic):
    async def on_client_request(self, method: str, params: JSON, servers: list[Server]) -> list[Server] | DirectResponse:
        if method == initialize_method:
            params[initialization_options] = dmerge(params.get(initialization_options, {}), {
                "command": ["golangci-lint", "run", "--output.json.path", "stdout", "--show-stats=false", "--issues-exit-code=1"],
            })
        return await super().on_client_request(method, params, servers)

def servers():
    return [
        ["gopls"],
        ["golangci-lint-langserver"],
    ]

def logic_class():
    return GoLogic
