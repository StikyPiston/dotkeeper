{
  description = "Swift devshell using Podman container";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};

    # Generate a policy.json
    podmanPolicy = pkgs.writeText "podman-policy.json" ''
      {
        "default": [
          {
            "type": "insecureAcceptAnything"
          }
        ]
      }
    '';
  in
  {
    devShells.${system}.default = pkgs.mkShell {
      packages = with pkgs; [
        podman
        bashInteractive
      ];

      shellHook = ''
        echo "Swift Development Shell"
        echo "Run 'enter-container' to (set up and) enter the Swift podman container"

        enter-container() {
          CONTAINER_NAME=swift-latest
          IMAGE=docker.io/library/swift:6.2
          WORKDIR=$(pwd)

          POLICY="${podmanPolicy}"

          if ! podman image exists "$IMAGE"; then
            echo "Pulling Swift image..."
            podman pull --signature-policy "$POLICY" "$IMAGE"
          fi

          if podman container exists "$CONTAINER_NAME"; then
            echo "Starting existing container..."
            podman start "$CONTAINER_NAME" >/dev/null
          else
            echo "Creating new container..."
            podman run \
              --signature-policy "$POLICY" \
              --interactive \
              --tty \
              --name "$CONTAINER_NAME" \
              --volume "$WORKDIR:/workspace:Z" \
              --workdir /workspace \
              "$IMAGE" \
              /bin/bash
            return
          fi

          echo "Attaching to container..."
          podman attach "$CONTAINER_NAME"
        }
      '';
    };
  };
}
