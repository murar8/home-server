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
