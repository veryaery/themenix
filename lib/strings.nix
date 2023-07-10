{ std, ... }:

let
    inherit (builtins)
        replaceStrings;

    inherit (std.strings)
        concatMapStringsSep;

    escapeFishArg = arg: "'${replaceStrings [ "'" "\\" ] [ "\\'" "\\\\" ] (toString arg)}'";

    escapeFishArgs = concatMapStringsSep " " escapeFishArg;
in
{
    inherit
        escapeFishArg
        escapeFishArgs;
}
