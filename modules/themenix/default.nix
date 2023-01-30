{
    themes ? {},
    themeName ? null,
    activationScript ? false
}:

{ config, pkgs, ... } @ args:

let 
    std = args.lib; 

    inherit (std.trivial)
        throwIf;

    inherit (std.modules)
        mkIf;

    inherit (std.options)
        mkEnableOption
        mkOption;

    inherit (std)
        types;

    drvsPath = ../../derivations;
    pkgs' = (((pkgs
        .extend (self: super: { substitutions-json = import (drvsPath + "/substitutions-json") super; }))
        .extend (self: super: {
            substitute-dir = import (drvsPath + "/substitute-dir") super;
            postinstall = import (drvsPath + "postinstall") super;
        }))
        .extend (self: super: {
            themes-dir = import (drvsPath + "/themes-dir") super;
            installtheme = import (drvsPath + "/installtheme") super;
        }))
        .extend (self: super: { themenix = import (drvsPath + "/themenix") super; });

    themenix = pkgs'.themenix.override {
        inherit themes;
        inherit (cfg)
            src
            files
            postInstallScripts;
    };

    cfg = config.theme;
in
{
    # TODO: test default values.
    # TODO: use asserts.
    options.theme = {
        enable = mkEnableOption "themenix";

        src = mkOption {
            type = types.path;
        };

        files = mkOption {
            type = types.functionTo (types.attrsOf types.attrs);
        };

        postInstallScripts = mkOption {
            type = types.attrsOf types.lines;
        };
    };

    config = mkIf cfg.enable {
        environment.systemPackages = [ themenix ];

        system.userActivationScripts.themenix.text = mkIf activationScript
            (throwIf (themeName == null)
            ("themeName is required while activationScript is enabled." + " " +
            "themenix was evaluated with a null themeName while activationScript was enabled.")
            "${themenix}/bin/installtheme ${themeName}");
    };
}
