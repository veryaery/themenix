pkgs:

let
    std = pkgs.lib;

    inherit (builtins)
        concatStringsSep
        isPath
        isString;

    inherit (std.lists)
        singleton;

    inherit (std.attrsets)
        mapAttrsToList;

    inherit (std.trivial)
        throwIf
        throwIfNot;
in

std.makeOverridable
({ src, name, files }:

let
    cmds =
        mapAttrsToList
        (file: opts:
            let
                srcFile =
                    if opts ? "src" then (
                        if isPath opts.src then
                            opts.src
                        else if isString opts.src then
                            throwIf (src == null) "substitute-dir was evaluated with a null src and file ${file} src is not a path."
                            (src + "/${opts.src}")
                        else
                            throw "File ${file} src is not of type path or string."
                    ) else
                        throwIf (src == null) "substitute-dir was evaluated with a null src and file ${file} has no src."
                        (src + "/${file}");
            in ''
                outFile=$out/${file}
                outFileDir=$(dirname $outFile)

                mkdir -p $outFileDir

                ${if opts ? "subs" then
                    let subsJson = pkgs.substitutions-json.override { inherit (opts) subs; };
                    in "mustache ${subsJson} ${srcFile} > $outFile"
                else
                    "cp --no-preserve=mode,ownership ${srcFile} $outFile"}

                if [ -x ${srcFile} ]; then
                    chmod +x $outFile
                fi
            ''
        )
        files;
in

pkgs.runCommandLocal
name
{ nativeBuildInputs = singleton pkgs.mustache-go; }
''

mkdir $out
${concatStringsSep "\n" cmds}

''

)
{
    src = null;
    name = null;
    files = {};
}
