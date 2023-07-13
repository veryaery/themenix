pkgs:

let
    std = pkgs.lib;

    inherit (builtins)
        attrNames
        elem
        filter;

    inherit (std.lists)
        foldr;

    inherit (std.attrsets)
        mapAttrsToList
        nameValuePair;
    
    inherit (std.asserts)
        assertMsg;
in

std.makeOverridable
({ themes, users, postInstallScripts }:

assert
    let
        usersAttrList = mapAttrsToList nameValuePair users;
        nonDefaultUsersAttrList = filter ({ name, ... }: name != "default") usersAttrList;
    in
        foldr
        ({ name, value }: z: z -> (
            assert assertMsg (value ? "defaultTheme")
                ("Every user must define a defaultTheme." + " " +
                "User ${name} is missing a defaultTheme.");
            assert assertMsg (elem value.defaultTheme (attrNames themes))
                "User ${name} defaultTheme ${value.defaultTheme} does not exist.";
            true
        ))
        true
        nonDefaultUsersAttrList;

let
    usersDir = pkgs.users-dir.override {
        inherit themes users;
    };
    installTheme = pkgs.install-theme.override {
        inherit themes usersDir postInstallScripts;
    };
in

pkgs.runCommandLocal
"themenix"
{}
''

mkdir -p $out/bin
cp ${installTheme} $out/bin/installtheme

''

)
{
    themes = {};
    users = {};
    postInstallScripts = {};
}
