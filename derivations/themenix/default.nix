pkgs:

let
    std = pkgs.lib;

    inherit (builtins)
        attrNames
        elem
        isString
        mapAttrs
        seq;

    inherit (std.trivial)
        throwIfNot;
in

std.makeOverridable
({ themes, users, postInstallScripts }:

let
    usersDir = pkgs.users-dir.override {
        inherit themes users;
    };
    installTheme = pkgs.install-theme.override {
        inherit themes usersDir postInstallScripts;
    };
in

(seq

# Assert users defaultTheme.
(mapAttrs (userKey: userValue:
    throwIfNot
    (userValue ? "defaultTheme")
    ("Every user must define a defaultTheme." + " " +
    "User ${userKey} is missing a defaultTheme.")
    (
        throwIfNot
        (elem userValue.defaultTheme (attrNames themes))
        "User ${userKey} defaultTheme ${userValue.defaultTheme} does not exist."
        userValue
    )
) users)

(pkgs.runCommandLocal
"themenix"
{}
''

mkdir -p $out/bin
cp ${installTheme} $out/bin/installtheme

'')

)

)
{
    themes = {};
    users = {};
    postInstallScripts = {};
}
