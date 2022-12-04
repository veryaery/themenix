std:

let
    module = import ./module.nix std;
    helper = import ./helper.nix std;
in
{
    inherit module;
    inherit (module)
        themenix;

    inherit helper;
    inherit (helper)
        eachTheme;
}
