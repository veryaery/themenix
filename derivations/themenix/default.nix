pkgs:

let
    std = pkgs.lib;
in

std.makeOverridable
({ themes, users, postInstallScripts }:

let
    usersDir = pkgs.users-dir.override {
        inherit themes users;
    };
    installTheme = pkgs.install-theme.override {
        inherit themesDir postInstallScripts;
    };
in

pkgs.runCommandLocal
"themenix"
{}
''

mkdir -p $out/bin
cp ${installtheme} $out/bin/installtheme

''

)
{
    themes = {};
    users = {};
    postInstallScripts = {};
}
