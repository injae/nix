{
  flake = {
    templates = rec {
      default = basic;
      basic = {
        path = ./basic;
        description = "Basic Flake";
      };
      rust = {
        path = ./rust;
        description = "Rust Flake";
      };
      python = {
        path = ./python;
        description = "Python Flake";
      };
      poetry = {
        path = ./python-poetry;
        description = "Python Poetry Flake";
      };
    };
  };
}
