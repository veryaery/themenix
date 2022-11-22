pkgs:

let
    std = pkgs.lib;
in

std.makeOverridable
({ lib, src, host }:

let
    themesDir = pkgs.themes-dir.override {
        inherit lib src;
        inherit (host) files;
    };
    installtheme = pkgs.installtheme.override {
        inherit themesDir;
        postInstallScripts =
            if host ? "postInstallScripts"
            then host.postInstallScripts
            else null;
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
    lib = null;
    src = null;
    host = null;
}
