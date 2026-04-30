{

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ...
    }:

    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

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

        templates.default.path = ./.;

        devShell = pkgs.mkShell {
          packages =
            buildInputs
            ++ nativeBuildInputs
            ++ (with pkgs; [
              # for setting up compile_commands
              bear
              # various utilities
              clang-tools
            ]);

          shellHook = "export BIN_NAME=${bin}";
        };
      }
    );
}
