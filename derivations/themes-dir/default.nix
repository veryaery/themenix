pkgs:

let
    std = pkgs.lib;

    inherit (builtins)
        concatStringsSep
        mapAttrs;

    inherit (std.attrsets)
        mapAttrsToList;
in

std.makeOverridable
({ themes, src, files }:

let
    themeDirs = 
        mapAttrs
        (themeName: theme:
            let
                files' =
                    if files == null
                    then {}
                    else files { inherit themeName theme; };
            in pkgs.substitute-dir.override {
                inherit src;
                name = themeName;
                files = files';
            }
        )
        themes;

    cmds =
        mapAttrsToList
        (themeName: themeDir: "ln -s ${themeDir} $out/${themeName}")
        themeDirs;
in

pkgs.runCommandLocal
"themes"
{}
''

mkdir $out
${concatStringsSep "\n" cmds}

''

)
{
    themes = {};
    src = null;
    files = null;
}
