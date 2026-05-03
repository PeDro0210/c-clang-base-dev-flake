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
            pkg-config
            # lsp support for Makefile
            autotools-language-server
          ];

          packages = with pkgs; [
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
            inherit buildInputs nativeBuildInputs;

            packages = packages;

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

          devShells = pkgs.mkShell {
            packages =
              buildInputs
              ++ nativeBuildInputs
              ++ (with pkgs; [
                # for setting up compile_commands
                compiledb
                # various utilities
                clang-tools
              ]);

            shellHook = "export BIN_NAME=${bin}";
          };

        };

    };
}
