pkgs:

let
    std = pkgs.lib;

    inherit (builtins)
        mapAttrs;
    
    inherit (import ./trivial.nix pkgs)
        importDir;
    
    themes = importDir ../themes;
    eachTheme = f: mapAttrs f themes;
in
{
    inherit
        eachTheme;
}
