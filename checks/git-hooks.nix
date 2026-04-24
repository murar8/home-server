{
  inputs,
  flake,
  system,
  ...
}:

inputs.git-hooks.lib.${system}.run {
  src = flake; # blueprint passes flake = self; coerced to source path
  hooks = {
    statix.enable = true;
    deadnix.enable = true;
    markdownlint.enable = true;
    actionlint.enable = true;
    shellcheck.enable = true;
    tflint.enable = true;
    terraform-format.enable = true;
    nil = {
      enable = true;
      settings.denyWarnings = true;
    };
    treefmt = {
      enable = true;
      package = flake.formatter.${system};
    };
  };
}
