{
  flake = {
    templates = rec {
      default = basic;
      basic = {
        description = "Basic Flake";
        path = ./basic;
      };
      rust = {
        description = "Rust Flake";
        path = ./rust;
      };
      python = {
        description = "Python Flake";
        path = ./python;
      };
      poetry = {
        description = "Python Poetry Flake";
        path = ./python-poetry;
      };
      gomod2nix = {
        description = "Go Mod to Nix Flake";
        path = ./gomod2nix;
      };
      go = {
        description = "Go Flake";
        path = ./go;
      };
    };
  };
}
