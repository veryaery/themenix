{ std, flakeRoot }:

let
    inherit (builtins)
        baseNameOf
        concatStringsSep
        isAttrs
        readDir;

    inherit (std.strings)
        splitString;

    inherit (std.attrsets)
        mapAttrs'
        nameValuePair;

    inherit (std.lists)
        init;

    inherit (std.trivial)
        const;
        
    baseNameOfExtentionless = s: concatStringsSep "." (init (splitString "." (baseNameOf s)));

    readThemes = themesPath: themeArgs:
        mapAttrs'
        (file: const (
            let
                themeName = baseNameOfExtentionless file;
                themeArgs' =
                    { inherit themeName; } //
                    (if themeArgs == null then {} else themeArgs);
                theme = import (themesPath + "/${file}") themeArgs';
            in nameValuePair themeName theme
        ))
        (readDir themesPath);

    themenix = { themes ? {}, themeArgs ? null }:
        let themes' =
            if isAttrs themes
            then themes
            else readThemes themes themeArgs;
        in import (flakeRoot + "/modules/themenix") { themes = themes'; };
in        
{
    inherit themenix;
}
