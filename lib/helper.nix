std:

let
    inherit (builtins)
        mapAttrs
        readDir;

    inherit (std.attrsets)
        mapAttrs'
        nameValuePair;
        
    baseNameOfExtentionless = s: stringBefore (lastPathComponent s) ".";

    eachTheme = themesPath: args: f:
        let
            themes =
                mapAttrs'
                (file: _:
                    let
                        themeName = baseNameOfExtentionless file;
                    in
                        nameValuePair
                        themeName
                        (
                            import (themesPath + "/${file}")
                            ({ inherit themeName; } // args)
                        )
                )
                (readDir themesPath);
        in
            mapAttrs
            (themeName: theme:
                let
                    module = import ../modules/themenix {
                        inherit themes themeName;
                        activationScript = true;
                    };
                    args' = {
                        inherit
                            themes
                            themeName
                            theme
                            module;
                    };
                in
                f args'
            )
            themes;
in
{
    inherit eachTheme;
}
