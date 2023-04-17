{ pkgs, ... }:
with pkgs.lib;
let
  # Maps an existing attribute set to a format that
  # can be accepted by `pre-commit-hooks.nix`.
  mkCiHooks = attrsets.mapAttrs'
    (name: command: attrsets.nameValuePair "ci-${name}"
      {
        enable = true;
        entry = pkgs.lib.mkForce command;
        files = "\\.(rs|toml)$";
        language = "rust";
        pass_filenames = false;
      });
in
{
  inherit mkCiHooks;
}
