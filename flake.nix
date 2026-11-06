{

  description = "A nix flake for c projects and environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-26.05";
    crane.url = "github:ipetkov/crane";
  };

  outputs =
    {
      nixpkgs,
      crane,
      ...
    }:
    let
      forAllSystems =
        function:
        nixpkgs.lib.genAttrs
          [
            "x86_64-linux"
            "aarch64-darwin"
          ]
          (
            system:
            let
              pkgs = nixpkgs.legacyPackages.${system};

              nativeBuildInputs = with pkgs; [
                pkg-config
              ];

              buildInputs = with pkgs; [
                libc
              ];

              # here goes the name of your binary
              bin = "clang_base_dev_flake";

            in
            function {
              inherit
                pkgs
                buildInputs
                nativeBuildInputs
                bin
                ;

            }
          );
    in
    {

      packages = forAllSystems (
        {
          pkgs,
          nativeBuildInputs,
          buildInputs,
          bin,
        }:
        {
          default = pkgs.clangStdenv.mkDerivation {
            inherit buildInputs nativeBuildInputs;
            name = "${bin}";
            src = ./.;

            BIN_NAME = bin;

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
        }
      );

      templates.default.path = ./.;

      devShells = forAllSystems (
        {
          pkgs,
          buildInputs,
          nativeBuildInputs,
        }:
        {
          default = pkgs.mkShell {
            inherit nativeBuildInputs buildInputs;
            packages = with pkgs; [
              clang-tools
              lldb

              compiledb
              makeWrapper
              autotools-language-server
            ];

          };
        }
      );

    };
}
