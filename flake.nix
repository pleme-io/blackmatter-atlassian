{
  description = "Blackmatter Atlassian — declarative acli + Rovo Dev provisioning for Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    substrate = {
      url = "github:pleme-io/substrate";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { self, nixpkgs, substrate, ... }:
    (import "${substrate}/lib/blackmatter-component-flake.nix") {
      inherit self nixpkgs;
      name = "blackmatter-atlassian";
      description = "Declarative Atlassian CLI + Rovo Dev provisioning";
      modules.homeManager = ./module;
    };
}
