{ std, ... }:

let
    inherit (builtins)
        concatStringsSep
        replaceStrings;

    escapeFishArg = arg: "'${replaceStrings [ "'" "\\" ] [ "\\'" "\\\\" ] (toString arg)}'";

    escapeFishArgs = concatStringsSep " " escapeFishArg;
in
{
    inherit
        escapeFishArg
        escapeFishArgs;
}
