import asyncio
from pathlib import Path

from rassumfrassum.frassum import LspLogic, Server, DirectResponse
from rassumfrassum.json import JSON
from rassumfrassum.util import dmerge

initialize_method = "initialize"
initialization_options = "initializationOptions"
workspace_configuration_method = "workspace/configuration"

yaml_settings = {
    "format": {
        "enable": False,
        "singleQuote": True,
    },
    "schemaStore": {
        "enable": True,
    },
    "kubernetesCRDStore": {
        "enable": True,
    },
    "hover": True,
    "completions": True,
    "validate": True,
    "schemas": {
        "https://json.schemastore.org/kustomization.json": "**/kustomization.yaml",
        "kubernetes": [
            "**/k8s/**/*.yaml",
        ],
    },
}


class YAMLLogic(LspLogic):
    async def on_client_request(
        self, method: str, params: JSON, servers: list[Server]
    ) -> list[Server] | DirectResponse:
        if method == initialize_method:
            params[initialization_options] = dmerge(
                params.get(initialization_options, {}),
                {"yaml": yaml_settings},
            )
        return await super().on_client_request(method, params, servers)

    async def on_server_request(
        self, method: str, params: JSON, source: Server
    ) -> DirectResponse | None:
        if method == workspace_configuration_method:
            items = params.get("items", [])
            results = []
            for item in items:
                section = item.get("section", "")
                if section == "yaml":
                    results.append(yaml_settings)
                else:
                    results.append(None)
            return DirectResponse(payload=results)
        return await super().on_server_request(method, params, source)


def servers():
    return [
        ["yaml-language-server", "--stdio"],
    ]


def logic_class():
    return YAMLLogic
