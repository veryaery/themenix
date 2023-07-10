{
    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
        flake-utils.url = "github:numtide/flake-utils";
    };

    outputs = { nixpkgs, flake-utils, ... } @ inputs:
    let
        std = nixpkgs.lib;

        flakeRoot = ./.;
        lib = import ./lib { inherit std flakeRoot; };

        packages = flake-utils.lib.eachDefaultSystem (system:
            let pkgs = import nixpkgs {
                localSystem = { inherit system; };
                overlays = [
                    (self: super: { substitutions-json = import ./derivations/substitutions-json super; })
                    (self: super: {
                        substitute-dir = import ./derivations/substitute-dir super;
                        install-user = import ./derivations/install-user super; })
                    (self: super: {
                        users-dir = import ./derivations/users-dir super;
                        install-theme = import ./derivations/install-theme super { inherit lib; };
                        activate = import ./derivations/activate super { inherit lib; }; })
                    (self: super: { themenix = import ./derivations/themenix super; })
                ];
            }; in {
                packages.default = pkgs.themenix;
            });
    in
    { inherit lib; } // packages;
}
