_:

{
  # flake path comes from `$PWD` when run inside the project dir (direnv + .envrc),
  # or from `$NH_OS_FLAKE` / `--flake` when invoked elsewhere
  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 7d --keep 3";
  };
}
