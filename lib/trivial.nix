pkgs:

let 
    std = pkgs.lib;

    inherit (builtins)
        attrNames
        baseNameOf
        concatStringsSep
        isAttrs
        isList
        isString
        mapAttrs
        readDir;
    
    inherit (std.lists)
        foldr
        init
        singleton;

    inherit (std.attrsets)
        mapAttrs'
        nameValuePair;
    
    inherit (std.strings)
        optionalString
        splitString;

    inherit (std.trivial)
        throwIfNot;

    baseNameOfExtentionless = s: concatStringsSep "." (init (splitString "." (baseNameOf s)));

    importDir = dir:
        mapAttrs'
        (file: _:
            nameValuePair
            (baseNameOfExtentionless file)
            (import (dir + "/${file}"))
        )
        (readDir dir);
    
    parseOpts' = parent: e:
        let
            path' = name: if parent == null then name else "${parent}:${name}";
            errPath = optionalString (parent != null) "${parent} ";
            checkStr = e: throwIfNot (isString e) "Option ${errPath}is not of type string.";
        in
        if isAttrs e then
            foldr
            (name: z:
                let
                    path = path' name;
                    value = e.${name};
                in z ++ (singleton path) ++ (parseOpts' path value)
            )
            []
            (attrNames e)
        else if isList e then
            foldr (x: z: z ++ (checkStr x (parseOpts' parent x))) [] e
        else
            let path = path' e;
            in checkStr e (singleton path);
        
    parseOpts = parseOpts' null;

    strSubs = e:
        if isAttrs e
        then mapAttrs (_: strSubs) e
        else { str = e; };

    fishTerminalColor = color:
        if hasPrefix "bright" color
        then "br" + toLower (substring 6 (stringLength color) color)
        else color;
in
{
    inherit
        fishTerinalColor
        importDir
        parseOpts
        strSubs;
}
