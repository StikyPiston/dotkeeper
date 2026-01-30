{
  description = "Dotkeeper devshell and package";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in {
        devShells.default = pkgs.mkShell {
          name = "dotkeeper-devshell";

          packages = with pkgs; [
            go
            gopls
            gotools
            delve
          ];
        };

        packages.dotkeeper = pkgs.buildGoModule {
          pname = "dotkeeper";
          version = "2026.01.29-a";

          src = self;

          vendorHash = "sha256-FBb8RFndx6wwdu08B95d+qas4VWs6Vr7UrXVGLyCW0g=";

          subPackages = [ "." ];
          ldflags = [ "-s" "-w" ];

          meta = with pkgs.lib; {
            description = "A simple, flexible symlink farm tool";
            license = licenses.mit;
            platforms = platforms.linux;
          };
        };

        apps.dotkeeper = {
          type = "app";
          program = "${self.packages.${system}.dotkeeper}/bin/dotkeeper";
        };
      });
}
