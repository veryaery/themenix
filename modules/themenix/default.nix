{ flakeRoot, lib } @ args:

{
    themes ? {}
}:

{ config, pkgs, ... } @ nixosModuleArgs:

let 
    std = args.lib; 

    inherit (builtins)
        attrNames
        elem
        isString
        mapAttrs
        seq;

    inherit (std.trivial)
        const
        throwIfNot;

    inherit (std.modules)
        mkIf;

    inherit (std.options)
        mkEnableOption
        mkOption;

    inherit (std)
        types;

    drvsPath = flakeRoot + "/derivations";
    pkgs' = (((pkgs
        .extend (self: super: { substitutions-json = import (drvsPath + "/substitutions-json") super; }))
        .extend (self: super: {
            substitute-dir = import (drvsPath + "/substitute-dir") super;
            install-user = import (drvsPath + "/install-user") super { inherit lib; };
        }))
        .extend (self: super: {
            users-dir = import (drvsPath + "/users-dir") super;
            install-theme = import (drvsPath + "/install-theme") super;
            activate = import (drvsPath + "/activate") super { inherit lib; };
        }))
        .extend (self: super: { themenix = import (drvsPath + "/themenix") super; });

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
                    type = types.str;
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

    config = mkIf cfg.enable (
        seq
        # Assert users defaultTheme.
        (mapAttrs (userKey: userValue:
            throwIfNot
            (userValue ? "defaultTheme")
            ("Every user must define a defaultTheme." + " " +
            "User ${userKey} is missing a defaultTheme.")
            (
                throwIfNot
                (elem userValue.defaultTheme (attrNames themes))
                "User ${userKey} defaultTheme ${userValue.defaultTheme} does not exist."
                userValue
            )
        ) cfg.users)
        {
            environment.systemPackages = [ themenix ];

            system.activationScripts.themenix.text = mkIf (cfg.postInstallScripts != {}) "${activate}";
        }
    );
}
