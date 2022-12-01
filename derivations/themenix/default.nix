pkgs:

let
    std = pkgs.lib;
in

std.makeOverridable
({ themes, src, files, postInstallScripts }:

let
    themesDir = pkgs.themes-dir.override {
        inherit themes src files;
    };
    installtheme = pkgs.installtheme.override {
        inherit themesDir postInstallScripts;
    };
in

pkgs.runCommandLocal
"dotfiles"
{}
''

mkdir -p $out/bin
cp ${installtheme} $out/bin/installtheme

''

)
{
    themes = {};
    src = null;
    files = null;
    postInstallScripts = {};
}
