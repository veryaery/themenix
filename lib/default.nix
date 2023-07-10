args:

let
    module = import ./module.nix args;
    strings = import ./strings.nix args;
in
{
    inherit module;
    inherit (module)
        themenix;

    inherit strings;
    inherit (strings)
        escapeFishArg
        escapeFishArgs;
}
