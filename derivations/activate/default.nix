pkgs:

{ lib }:

let
    std = pkgs.lib;

    inherit (lib.strings)
        escapeFishArgs;

    activate-user = { themes, usersDir, postInstallScripts }:
        let
            installUser = pkgs.install-user.override { inherit usersDir postInstallScripts; };
        in
            pkgs.writeScript
            "activateuser"
            ''
                set -l themeNames ${escapeFishArgs themeNames}

                set -q XDG_DATA_DIR; or set XDG_DATA_DIR $HOME/.local/share
                set -l activeThemeFile $XDG_DATA_DIR/themenix/active_theme
                set -l defaultThemeFile (realpath ${usersDir}/(whoami)/default_theme)

                set -l defaultTheme (cat $defaultThemeFile)
                set -l activeTheme
                [ -e $activeThemeFile ]; and set activeTheme (cat $activeThemeFile)

                if contains $activeTheme $themeNames
                    ${installUser} $activeTheme
                else
                    ${installUser} $defaultTheme
                end
            '';
in

std.makeOverridable
({ themes, usersDir, postInstallScripts }:

let
    activateUser = activate-user { inherit themes usersDir postInstallScripts; };
in

pkgs.writeScriptBin
"activate"

''

#!${pkgs.fish}/bin/fish

for user in (ls -A ${usersDir})
    ${pkgs.su}/bin/su -c ${activateUser} - $user
end

''

)
{
    themes = {};
    usersDir = null;
    postInstallScripts = {};
}
