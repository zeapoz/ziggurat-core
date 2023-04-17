{
  description = "Nix development environment for Ziggurat";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
  };

  outputs = { self, nixpkgs, flake-utils, rust-overlay, pre-commit-hooks, ... }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          overlays = [ (import rust-overlay) ];
          pkgs = import nixpkgs {
            inherit system overlays;
          };

          lib = import ./lib.nix { inherit pkgs; };

          # Latest stable rust without rustfmt.
          stable-rust = pkgs.rust-bin.stable.latest.minimal.override {
            extensions = [ "clippy" "rust-docs" ];
          };
          # Latest nightly rust with rustfmt.
          nightly-rust = pkgs.rust-bin.selectLatestNightlyWith
            (toolchain: toolchain.minimal.override {
              extensions = [ "rustfmt" ];
            });

          buildInputs = with pkgs; [
            stable-rust
            nightly-rust
            cargo-sort
            openssl
            pkg-config
          ];
        in
        {
          inherit lib buildInputs;

          checks = {
            pre-commit-check = pre-commit-hooks.lib.${system}.run {
              src = ./.;
              hooks = {
                # Nix.
                deadnix.enable = true;
                nil.enable = true;
                nixpkgs-fmt.enable = true;
                statix.enable = true;
              } // (lib.mkCiHooks self.scripts);
            };
          };

          devShells.default = pkgs.mkShell {
            inherit (self.checks.${system}.pre-commit-check) shellHook;

            buildInputs = self.buildInputs.${system};
          };
        }) // {
      scripts = {
        check = "cargo check --all-targets";
        fmt = "cargo fmt --all -- --check";
        clippy = "cargo clippy --all-targets -- -D warnings";
        sort = "cargo-sort --check --workspace";
      };

      templates.default = {
        path = ./nix-template;
        description = "Nix template for working with Ziggurat";
      };
    };
}
