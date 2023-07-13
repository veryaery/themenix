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
set -l sourceUsers (${pkgs.coreutils}/bin/ls -A ${usersDir} | string split -n default)

argparse "u/user=" "g/global" -- $argv

if [ (builtin count $argv) -lt 1 ]
    ${pkgs.coreutils}/bin/echo (builtin set_color red)No theme was provided.(builtin set_color normal) >&2
    ${pkgs.coreutils}/bin/echo (builtin set_color green)Available themes:(builtin set_color normal) $themeNames >&2
    return 1
end

set -l themeName $argv[1]

if ! builtin contains $themeName $themeNames
    ${pkgs.coreutils}/bin/echo (builtin set_color red)The theme $themeName does not exist.(builtin set_color normal) >&2
    ${pkgs.coreutils}/bin/echo (builtin set_color green)Available themes:(builtin set_color normal) $themeNames >&2
    return 1
end

set -l sourceUser
if set -q _flag_user
    set sourceUser $_flag_user
    if ! builtin contains $_flag_user $sourceUsers
        ${pkgs.coreutils}/bin/echo (builtin set_color red)The user $sourceUser is not defined in this themenix configuration.(builtin set_color normal) >&2
        ${pkgs.coreutils}/bin/echo (builtin set_color green)Available users:(builtin set_color normal) $sourceUsers >&2
        return 1
    end
end

set -l args $themeName

[ -n "$sourceUser" ]; and set -a args -u $sourceUser

if set -q _flag_global
    for targetUser in $sourceUsers
        ${installUser} $targetUser $args
    end
else
    ${installUser} (${pkgs.coreutils}/bin/whoami) $args
end

''

)
{
    themes = {};
    usersDir = null;
    postInstallScripts = {};
}
