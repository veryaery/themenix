{
    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
        flake-utils.url = "github:numtide/flake-utils";
    };

    outputs = { nixpkgs, flake-utils, ... } @ inputs:
    let
        std = nixpkgs.lib;
        lib = import ./lib std;
        packages = flake-utils.lib.eachDefaultSystem (system:
            let pkgs = import nixpkgs {
                localSystem = { inherit system; };
                overlays = [
                    (self: super: { substitutions-json = import ./derivations/substitutions-json super; })
                    (self: super: {
                        substitute-dir = import ./derivations/substitute-dir super;
                        postinstall = import ./derivations/postinstall super; })
                    (self: super: {
                        themes-dir = import ./derivations/themes-dir super;
                        installtheme = import ./derivations/installtheme super; })
                    (self: super: { themenix = import ./derivations/themenix super; })
                ];
            }; in
            { packages.default = pkgs.themenix; });
    in
    { inherit lib; } // packages;
}
