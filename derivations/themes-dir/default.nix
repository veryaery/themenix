pkgs:

let
    std = pkgs.lib;

    inherit (builtins)
        concatStringsSep;

    inherit (std.attrsets)
        mapAttrsToList;
in

std.makeOverridable
({ lib, src, files }:

let
    inherit (lib.themes)
        eachTheme;

    themeDirs = eachTheme (themeName: theme:
        let
            theme' = theme { inherit themeName pkgs lib; };
            files' = files {
                inherit themeName;
                theme = theme';
            };
        in pkgs.substitute-dir.override {
            inherit src;
            name = themeName;
            files = files';
        }
    );

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
    lib = null;
    src = null;
    files = null;
}
