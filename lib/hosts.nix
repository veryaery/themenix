pkgs:

let
    std = pkgs.lib;

    inherit (builtins)
        attrNames;

    inherit (std.lists)
        foldr;
    
    inherit (import ./trivial.nix pkgs)
        importDir;
    
    hosts = importDir ../hosts;
    eachHost = f:
        foldr
        (hostName: z:
            let host = hosts.${hostName};
            in z // (f hostName host)
        )
        {}
        (attrNames hosts);
in
{
    inherit
        eachHost;
}
