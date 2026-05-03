{

  description = "A nix flake for c projects and environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-25.11";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    {
      flake-parts,
      ...
    }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {

      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];

      flake = {
        templates.default.path = ./.;
      };

      perSystem =
        {
          config,
          self',
          inputs',
          pkgs,
          system,
          ...
        }:
        let

          nativeBuildInputs = with pkgs; [
            compiledb
            pkg-config
            # lsp support for Makefile
            autotools-language-server
            makeWrapper
          ];

          buildInputs = with pkgs; [
            libc
          ];

          # here goes the name of your binary
          bin = "clang_base_dev_flake";

        in
        {

          packages.default = pkgs.clangStdenv.mkDerivation {
            name = "${bin}";
            src = ./.;

            BIN_NAME = bin;
            inherit buildInputs nativeBuildInputs;

            buildPhase = ''
              runHook preBuild

              export BIN_NAME=${bin}

              make dir
              make build

              runHook postBuild
            '';

            installPhase = ''
              runHook preInstall

              mkdir -p $out/bin
              cp -ra bin/* $out/bin

              runHook postInstall
            '';

          };

        };

    };
}
