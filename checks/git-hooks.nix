{
  inputs,
  flake,
  system,
  ...
}:

inputs.git-hooks.lib.${system}.run {
  src = flake;
  hooks = {
    statix.enable = true;
    markdownlint.enable = true;
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
