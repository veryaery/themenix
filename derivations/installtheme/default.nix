pkgs:

let
    std = pkgs.lib;

    inherit (builtins)
        concatStringsSep
        mapAttrsToList;

    inherit (std.strings)
        optionalString;
in

std.makeOverridable
({ themesDir, postInstallScripts }:

let
    cmds = optionalString (postInstallScripts != null) (
        mapAttrsToList
        (name: script: ''
            # ----- ${name} ------
            ${script}
            # -----
        '')
        postInstallScripts
    );
in

pkgs.writeScript
"installtheme"

''
#!${pkgs.fish}/bin/fish

if [ (count $argv) -lt 1 ]
    echo (set_color red)No theme was provided.(set_color normal) >&2
    echo (set_color green)Available themes:(set_color normal) (ls -A ${themesDir}) >&2
    return 1
end

set -l themeName $argv[1]
set -l themeDir (realpath ${themesDir}/$themeName)

if [ ! -d $themeDir ]
    echo (set_color red)The theme $themeName does not exist.(set_color normal) >&2
    echo (set_color green)Available themes:(set_color normal) (ls -A ${themesDir}) >&2
    return 1
end

set -q XDG_DATA_DIR; or set XDG_DATA_DIR $HOME/.local/share
set -l trackedFilesFile $XDG_DATA_DIR/themenix/tracked_files
set -l trackedFiles
[ -e $trackedFilesFile ]; and set trackedFiles (cat $trackedFilesFile)

if [ (count $trackedFiles) -gt 0 ]
    set -l deferredDirs

    set -l invalidated true
    while [ $invalidated = true ]
        set invalidated false

        for file in $trackedFiles
            set -l homeFile $HOME/$file
            set -l themeFile $themeDir/$file

            [ -e $themeFile ]; and continue

            if [ ! -e $homeFile ]
                # tracked file has already been removed. remove from tracked files list.
                set trackedFiles (string split -n $file $trackedFiles)
                continue
            end

            if [ -d $homeFile ]
                if [ -n "$(ls -A $homeFile)" ]
                    # dir contains files. defer removal.
                    ! contains $file $deferredDirs; and set -a deferredDirs $file
                else
                    # dir is empty. free to rm.
                    rm -r $homeFile
                    set deferredDirs (string split -n $file $deferredDirs)
                    set trackedFiles (string split -n $file $trackedFiles)
                    set invalidated true
                end
                continue
            end

            if [ -e $homeFile ]
                rm $homeFile
                set trackedFiles (string split -n $file $trackedFiles)
                set invalidated true
            end
        end
    end

    # untrack any deferred dirs which couldn't be removed.
    for dir in $deferredDirs
        set trackedFiles (string split -n $dir $trackedFiles)
        set_color yellow
        echo The tracked directory $dir should have been removed but couldn\'t because it contains untracked files.
        echo The directory has been untracked and must be managed manually from now on.
        set_color normal
    end
end

for themeFile in (find $themeDir -type f)
    set -l file (string split -n -m1 $themeDir/ $themeFile)
    set -l homeFile $HOME/$file

    # ensure that parent directories exist and add any directories we make to tracked files list.
    set -l segments (string split / (dirname $file))
    for i in (seq (count $segments))
        set -l dir (string join / $segments[(seq $i)])
        set -l homeDir $HOME/$dir

        if [ ! -e $homeDir ]
            mkdir $homeDir
            set -a trackedFiles $dir
        end
    end

    cp --no-preserve=mode,ownership $themeFile $homeFile
    if [ -x $themeFile ]
        chmod +x $homeFile
    else
        chmod -x $homeFile
    end

    ! contains $file $trackedFiles; and set -a trackedFiles $file
end

mkdir -p (dirname $trackedFilesFile)
truncate -s 0 $trackedFilesFile
string join \n $trackedFiles > $trackedFilesFile

set -U THEMENIX_THEME_NAME $themeName

${concatStringsSep "\n\n" cmds}
''

)
{
    themesDir = null;
    postInstallScripts = null;
}
