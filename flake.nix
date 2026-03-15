{
  description = "Declarative Atlassian CLI + Rovo Dev provisioning for Nix";

  outputs = { self, ... }: {
    homeManagerModules.default = import ./module;
  };
}
