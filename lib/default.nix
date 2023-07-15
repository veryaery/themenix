args:

let
    module = import ./module.nix args;
    strings = import ./strings.nix args;
in
{
    inherit module;
    inherit (module)
        makeThemenixWrapper;

    inherit strings;
    inherit (strings)
        escapeFishArg
        escapeFishArgs;
}
