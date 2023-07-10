pkgs:

{ lib }:

let
    std = pkgs.lib;

    inherit (builtins)
        attrNames;

    inherit (lib.strings)
        escapeFishArgs;
in

std.makeOverridable
({ themes, usersDir, postInstallScripts }:

let
    themeNames = attrNames themes;

    installUser = pkgs.install-user.override { inherit usersDir postInstallScripts; };
in

pkgs.writeScript
"installtheme"

''

#!${pkgs.fish}/bin/fish

set -l themeNames ${escapeFishArgs themeNames}

argparse "g/global" -- $argv

if [ (count $argv) -lt 1 ]
    echo (set_color red)No theme was provided.(set_color normal) >&2
    echo (set_color green)Available themes:(set_color normal) $themeNames >&2
    return 1
end

set -l themeName $argv[1]

if ! contains $themeName $themeNames
    echo (set_color red)The theme $themeName does not exist.(set_color normal) >&2
    echo (set_color green)Available themes:(set_color normal) $themeNames >&2
    return 1
end

if [ -n "$_flag_global" ]
    for user in (ls -A ${usersDir})
        ${pkgs.su}/bin/su -c ${installUser} - $user
    end
else
    ${installUser} $themeName
end

''

)
{
    themes = {};
    usersDir = null;
    postInstallScripts = {};
}
