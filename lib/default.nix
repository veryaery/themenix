std:

let
    module = import ./module std;
    helper = import ./helper std;
in
{
    inherit module;
    inherit (module)
        themenix;

    inherit helper;
    inherit (helper)
        eachTheme;
}
