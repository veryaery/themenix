{ hostName, pkgs, lib }:

{

    options = {
        flavor = [
            "vanilla"
            "chocolate"
        ];
    };

    host = { option }:
        {
            
            files = { themeName, theme }:
                {
                    # "colors.md".subs = builtins.mapAttrs (name: value: { str = value; }) theme;
                    # "profile.md".subs = builtins.mapAttrs (name: value: { str = value; }) theme;
                    # "foo/bar/baz" = {};
                };

        };

}
