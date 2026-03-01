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
          autotools-language-server
        ];

        packages = with pkgs; [
          makeWrapper
        ];

        buildInputs = with pkgs; [
          libcxx
        ];

        # here goes the name of your binary
        bin = "";

      in
      {

        packages.default = pkgs.clangStdenv.mkDerivation {
          name = "${bin}";
          src = ./.;
          inherit buildInputs nativeBuildInputs;

          packages = packages;

          buildPhase = ''
            runHook preBuild

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

        devShell = pkgs.mkShell {
          packages =
            buildInputs
            ++ nativeBuildInputs
            ++ (with pkgs; [
              bear
              clang-tools
              valgrind
              lldb
            ]);

          shellHook = "export BIN_NAME ${bin}";
        };
      }
    );
}
