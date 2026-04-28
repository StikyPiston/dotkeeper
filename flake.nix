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
          version = "2026.04.28-a";

          src = self;

          vendorHash = "sha256-g+39YPEaohp4BJjwRXiqUY2viZPimvf1pOjtyAFOjNY=";

          subPackages = [ "." ];
          ldflags = [ "-s" "-w" ];

          meta = with pkgs.lib; {
            description = "A simple, flexible symlink farm tool";
            license = licenses.mit;
            platforms = platforms.all;
          };
        };

        apps.dotkeeper = {
          type = "app";
          program = "${self.packages.${system}.dotkeeper}/bin/dotkeeper";
        };
      });
}
