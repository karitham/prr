{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };
  outputs = {nixpkgs, ...}: let
    systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
    forEachSystem = nixpkgs.lib.genAttrs systems;
  in {
    packages = forEachSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      prr = pkgs.callPackage (
        {
          lib,
          rustPlatform,
          openssl,
          pkg-config,
          cacert,
        }:
        # https://github.com/NixOS/nixpkgs/blob/7df7ff7d8e00218376575f0acdcc5d66741351ee/pkgs/by-name/pr/prr/package.nix#L30
          rustPlatform.buildRustPackage {
            pname = "prr";
            version = "devel";

            src = ./.;

            cargoHash = "sha256-W66kbTk0IAThl2H35EYuXr6UAyWfhmV0DxpnABhppSQ=";

            buildInputs = [openssl];

            nativeBuildInputs = [pkg-config];

            SSL_CERT_FILE = "${cacert}/etc/ssl/certs/ca-bundle.crt";
            checkInputs = [cacert];

            meta = with lib; {
              description = "Tool that brings mailing list style code reviews to Github PRs";
              homepage = "https://github.com/danobi/prr";
              license = licenses.gpl2Only;
              mainProgram = "prr";
            };
          }
      ) {};
    in {
      default = prr;
      prr = prr;
    });

    devShells = forEachSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      default = pkgs.mkShell {
        buildInputs = with pkgs; [
          rustc
          cargo
          rustfmt
          rust-analyzer
          clippy

          pkg-config
          openssl

          cacert
        ];

        RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";
        SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
        PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
      };
    });
  };
}
