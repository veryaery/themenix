{ themes, themeName, activationScript }:

{ config, ... } @ args:

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
    pkgs = (((args.pkgs
        .extend (self: super: { substitutions-json = import (drvsPath + "/substitutions-json") super; }))
        .extend (self: super: { substitute-dir = import (drvsPath + "/substitute-dir") super; }))
        .extend (self: super: {
            themes-dir = import (drvsPath + "/themes-dir") super;
            installtheme = import (drvsPath + "/installtheme") super;
        }))
        .extend (self: super: { themenix = import (drvsPath + "/themenix") super; });

    themenix = pkgs.themenix.override {
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
    options.theme = {
        enable = mkEnableOption "themenix";

        src = mkOption {
            type = types.package;
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
            (throwIf (themeName == null) "TODO"
            "${themenix}/bin/installtheme ${themeName}");
    };
}
