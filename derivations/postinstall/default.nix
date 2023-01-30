pkgs:

let
    std = pkgs.lib;

    inherit (builtins)
        concatStringsSep;

    inherit (std.attrsets)
        mapAttrsToList;
in

std.makeOverridable
({ postInstallScripts }:

let
    scripts =
        mapAttrsToList
        (name: script: ''
            # ----- ${name} ------
            ${script}
            # -----
        '')
        postInstallScripts;
in

pkgs.writeShellScript "postinstall"
(concatStringsSep "\n\n" scripts)

)
{ postInstallScripts = {}; }
