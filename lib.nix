{ pkgs, ... }:
with pkgs.lib;
let
  ciScriptTemplate = { name, command }: ''
    echo -e "${name}:"
    echo "Running \"${command}\"..."
    ${command} \
    && echo -e "\033[0;32mSucceeded!\033[0m" \
    || (s=$?; echo -e "\033[0;31mFailed!\033[0m"; exit $s)
  '';

  # Wrapper function around `mkCiScriptsBin` and `mkCiScriptBin`.
  # Outputs a list containing the results of both functions.
  mkCiScripts = s: (mkCiScriptsBin s) ++ [ (mkCiAllScriptBin s) ];

  # Writes an executable script for each entry in an attribute set.
  mkCiScriptsBin = attrsets.mapAttrsToList
    (name: command: (pkgs.writeShellScriptBin "ci-${name}"
      (ciScriptTemplate { inherit name command; })));

  # Writes an executable script that will run all entries in an attribute set.
  mkCiAllScriptBin = s: pkgs.writeShellScriptBin "ci-all"
    (strings.concatStringsSep "\necho\n"
      (attrsets.mapAttrsToList
        (name: command: (ciScriptTemplate { inherit name command; }))
        s));

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
  inherit
    mkCiScripts
    mkCiHooks;
}
