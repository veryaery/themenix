{ flakeRoot, lib } @ args:

{
    themes ? {}
}:

{ config, pkgs, ... } @ nixosModuleArgs:

let 
    std = args.lib; 

    inherit (std.trivial)
        const;

    inherit (std.modules)
        mkIf;

    inherit (std.options)
        mkEnableOption
        mkOption;

    inherit (std)
        types;

    drvsPath = flakeRoot + "/derivations";
    pkgs' = pkgs.extend (self: super: {
        substitutions-json = import (drvsPath + "/substitutions-json") self;
        substitute-dir = import (drvsPath + "/substitute-dir") self;
        install-user = import (drvsPath + "/install-user") self;
        users-dir = import (drvsPath + "/users-dir") self;
        install-theme = import (drvsPath + "/install-theme") self { inherit lib; };
        activate = import (drvsPath + "/activate") self { inherit lib; };
        themenix = import (drvsPath + "/themenix") self;
    });

    themenix = pkgs'.themenix.override {
        inherit themes;
        inherit (cfg)
            users
            postInstallScripts;
    };

    usersDir = pkgs'.users-dir.override {
        inherit themes;
        inherit (cfg) users;
    };

    activate = pkgs'.activate.override {
        inherit themes usersDir;
        inherit (cfg) postInstallScripts;
    };

    cfg = config.theme;
in
{
    options.theme = {
        enable = mkEnableOption "themenix";

        users = mkOption {
            type = types.attrsOf (types.submodule ({ options = {
                defaultTheme = mkOption {
                    type = types.nullOr types.str;
                };

                src = mkOption {
                    type = types.nullOr types.path;
                };

                files = mkOption {
                    type = types.functionTo (types.attrsOf types.attrs);
                    default = const {};
                };
            }; }));
        };

        postInstallScripts = mkOption {
            type = types.attrsOf types.lines;
        };
    };

    config = mkIf cfg.enable {
        environment.systemPackages = [ themenix ];

        system.activationScripts.themenix.text = mkIf (cfg.postInstallScripts != {}) "${activate}";
    };
}
