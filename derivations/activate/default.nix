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
                #!${pkgs.fish}/bin/fish

                set -l themeNames ${escapeFishArgs themeNames}

                set -l targetUser $argv[1]

                set -l targetHomeDir (${pkgs.getent}/bin/getent passwd $targetUser | ${pkgs.coreutils}/bin/cut -d : -f 6)
                set -l targetXdgDataHome (${pkgs.su}/bin/su -s ${pkgs.bash}/bin/bash -c "${pkgs.coreutils}/bin/echo $XDG_DATA_HOME" - $targetUser)
                [ -n "$targetXdgDataHome" ]; or set targetXdgDataHome $targetHomeDir/.local/share

                set -l activeThemeFile $targetXdgDataHome/themenix/active_theme
                set -l defaultThemeFile (${pkgs.coreutils}/bin/realpath ${usersDir}/$targetUser/default_theme)

                set -l defaultTheme (${pkgs.coreutils}/bin/cat $defaultThemeFile)
                set -l activeTheme
                [ -e $activeThemeFile ]; and set activeTheme (${pkgs.coreutils}/bin/cat $activeThemeFile)

                if builtin contains $activeTheme $themeNames
                    ${installUser} $targetUser $activeTheme
                else
                    ${installUser} $targetUser $defaultTheme
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

set -l sourceUsers (${pkgs.coreutils}/bin/ls -A ${usersDir} | string split -n default)

for targetUser in $sourceUsers
    ${activateUser} $targetUser
end

''

)
{
    themes = {};
    usersDir = null;
    postInstallScripts = {};
}
