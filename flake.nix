{
    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
        flake-utils.url = "github:numtide/flake-utils";
    };

    outputs = { nixpkgs, flake-utils, ... } @ inputs:
    let
        inherit (builtins)
            listToAttrs
            map;

        src = ./dotfiles;
    in
    flake-utils.lib.eachDefaultSystem (system:
        let
            pkgs = import nixpkgs {
                localSystem = { inherit system; };
                overlays = [
                    (self: super: { substitutions-json = import ./derivations/substitutions-json super; })
                    (self: super: { substitute-dir = import ./derivations/substitute-dir super; })
                    (self: super: {
                        themes-dir = import ./derivations/themes-dir super;
                        installtheme = import ./derivations/installtheme super;
                    })
                    (self: super: { themenix = import ./derivations/themenix super; })
                ];
            };
            std = pkgs.lib;
            lib = import ./lib pkgs;

            inherit (std.attrsets)
                nameValuePair;

            inherit (std.lists)
                singleton;

            inherit (lib.trivial)
                parseOpts;
        in
        {
            packages = lib.hosts.eachHost (hostName: host:
                let
                    host' = host { inherit hostName pkgs lib; };
                    parsedOpts =
                        if host' ? "options"
                        then parseOpts host'.options
                        else [];
                in
                listToAttrs 
                (                    
                    map
                    (opt:
                        let
                            host'' = host'.host { option = opt; };
                            name = if opt == null then hostName else "${hostName}:${opt}";
                            value = pkgs.dotfiles.override {
                                inherit lib src;
                                host = host'';
                            };
                        in
                        nameValuePair name value
                    )
                    ((singleton null) ++ parsedOpts)
                )
            );
        }
    );
}
