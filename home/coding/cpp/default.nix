{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # build-tool
    libtool
    gnumake

    #stdenv
    #clangStdenv
    #vscode-extensions.vadimcn.vscode-lldb
    #llvmPackages_17.stdenv
    #llvmPackages_17.libcxxStdenv
    #llvmPackages_17.bintools-unwrapped
    #llvmPackages_17.clangUseLLVM
    #clang
    #gcc13
    ccls
    ccache
    lcov

    cmake
    cmake-format
    cmake-language-server
  ];
}
