pkgs:

let
    std = pkgs.lib;

    inherit (builtins)
        attrNames
        attrValues
        isAttrs
        isString
        toJSON
        concatStringsSep;

    inherit (std.trivial)
        throwIfNot;

    inherit (std.lists)
        foldr
        singleton;

    inherit (std.attrsets)
        mapAttrsToList;

    inherit (std.strings)
        escapeShellArg;

    isNestedAttrs = e:
        (isAttrs e) && (
            foldr
            (value: z: (isAttrs value) || z)
            false
            (attrValues e)
        );

    parseSubs' = parent: attrs:
        foldr
        (name: z:
            let
                path = if parent == null then name else "${parent}.${name}";
                value = attrs.${name};
            in
            if isNestedAttrs value then
                # value is nested substitutions. Merge nested substitutions.
                let
                    parsedValue = parseSubs' path value;
                in
                {
                    strs = (
                        if parsedValue.strs == {}
                        then z.strs
                        else z.strs // { ${name} = parsedValue.strs; }
                    );
                    cmds = z.cmds // parsedValue.cmds;
                }
            else
                # value is a substitution. Merge substitution attribute.
                throwIfNot (isAttrs value) "Substitution ${path} is not of type attrset."
                (if value ? "str" && value ? "cmd" then
                    throw "Substitutions may only have one of str or cmd. Substitution ${path} has both a str and a cmd."
                else if value ? "str" then
                    throwIfNot (isString value.str) "Substitution ${path} str is not of type string."
                    (z // { strs = z.strs // { ${name} = value.str; }; })
                else if value ? "cmd" then
                    throwIfNot (isString value.cmd) "Substitution ${path} cmd is not of type string."
                    (z // { cmds = z.cmds // { ${path} = value.cmd; }; })
                else
                    throw "Substitutions must have one of str or cmd. Substitution ${path} is missing either a str or a cmd.")
        )
        { strs = {}; cmds = {}; }
        (attrNames attrs);

    parseSubs = parseSubs' null;
in

std.makeOverridable
({ subs }:

let
    parsedSubs = parseSubs subs;

    strsJson = pkgs.writeTextFile {
        name = "substitutions.json";
        text = toJSON parsedSubs.strs;
    };

    cmds =
        mapAttrsToList
        (path: cmd: 
            cmd + " " +
            "| sed " +
                "'" +
                    "s/\\\\/\\\\\\\\/g ; " +
                    "s/\"/\\\\\\\"/g ; " +
                    "s/^/\"/ ; " +
                    "s/$/\"/" +
                "' " +
            "| jq " +
                "--arg path ${escapeShellArg path} " +
                "'setpath($path | split(\".\"); input)' " +
                "$out " +
                "- " +
            "> tmp && mv tmp $out"
        )
        parsedSubs.cmds;
in

pkgs.runCommandLocal
"substitutions.json"
{ nativeBuildInputs = singleton pkgs.jq; }
''

cat ${strsJson} > $out
${concatStringsSep "\n" cmds}

''

)
{ subs = {}; }
