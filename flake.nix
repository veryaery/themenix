{
    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
        flake-utils.url = "github:numtide/flake-utils";
    };

    outputs = { nixpkgs, flake-utils, ... } @ inputs:
    let
        std = nixpkgs.lib;
        lib = import ./lib { inherit std; };

        inherit (lib)
            makeThemenixWrapper;

        overlay = self: super: {
            substitutions-json = import ./derivations/substitutions-json self;
            substitute-dir = import ./derivations/substitute-dir self;
            install-user = import ./derivations/install-user self;
            users-dir = import ./derivations/users-dir self;
            install-theme = import ./derivations/install-theme self { inherit lib; };
            activate = import ./derivations/activate self { inherit lib; };
            themenix = import ./derivations/themenix self;
        };

        outputs = flake-utils.lib.eachDefaultSystem (system:
            let pkgs = nixpkgs.legacyPackages.${system}.extend overlay;
            in { packages.default = pkgs.themenix; }
        );
    in outputs // { nixosModules.default = makeThemenixWrapper (./modules/themenix { lib, overlay }); }
}
