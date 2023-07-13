pkgs:

let
    std = pkgs.lib;

    inherit (builtins)
        concatStringsSep
        mapAttrs;

    inherit (std.attrsets)
        mapAttrsToList;

    inherit (std.trivial)
        const;

    inherit (std.strings)
        escapeShellArg
        optionalString;
   
    themes-dir = themes: { src, files }:
        let
            themeDirs =
                mapAttrs
                (themeName: theme: pkgs.substitute-dir.override {
                    inherit src;
                    name = themeName;
                    files = files { inherit themeName theme; };
                })
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
            '';

    user-dir = userKey: themes: { defaultTheme, src, files } @ userValue:
        let themesDir = themes-dir themes { inherit src files; };
        in
            pkgs.runCommandLocal
            userKey
            {}
            ''
                mkdir $out
                ${
                    optionalString (defaultTheme != null)
                    "echo ${escapeShellArg defaultTheme} > $out/default_theme"
                }
                ln -s ${themesDir} $out/themes
            '';
in

std.makeOverridable
({ themes, users }:

let
    userDirs =
        mapAttrs
        (userKey: userValue: user-dir userKey themes userValue)
        users;

    cmds =
        mapAttrsToList
        (user: userDir: "ln -s ${userDir} $out/${user}")
        userDirs;
in

pkgs.runCommandLocal
"users"
{}
''

mkdir $out
${concatStringsSep "\n" cmds}

''

)
{
    themes = {};
    users = {};
}
