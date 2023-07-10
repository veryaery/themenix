pkgs:

let
    std = pkgs.lib;

    inherit (builtins)
        concatStringsSep;
    
    inherit (std.attrsets)
        mapAttrsToList;

    post-install = { postInstallScripts }:
        let scripts =
            mapAttrsToList
            (name: script: ''
                # ----- ${name} ------
                ${script}
                # -----
            '')
            postInstallScripts;
        in
            pkgs.writeShellScript
            "postinstall"
            (concatStringsSep "\n\n" scripts);
in

std.makeOverridable
({ usersDir, postInstallScripts }:

let
    postInstall = post-install { inherit postInstallScripts; };
in

pkgs.writeScript
"installuser"

''
#!${pkgs.fish}/bin/fish

set -l themeName $argv[1]

set -q XDG_DATA_DIR; or set XDG_DATA_DIR $HOME/.local/share
set -l dataDir $XDG_DATA_DIR/themenix
set -l trackedFilesFile $dataDir/tracked_files
set -l activeThemeFile $dataDir/active_theme

set -l themeDir (${pkgs.coreutils}/bin/realpath ${usersDir}/(whoami)/themes/$themeName)
set -l trackedFiles
[ -e $trackedFilesFile ]; and set trackedFiles (${pkgs.coreutils}/bin/cat $trackedFilesFile)

if [ (builtin count $trackedFiles) -gt 0 ]
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
                if [ -n "$(${pkgs.coreutils}/bin/ls -A $homeFile)" ]
                    # dir contains files. defer removal.
                    ! builtin contains $file $deferredDirs; and set -a deferredDirs $file
                else
                    # dir is empty. free to rm.
                    ${pkgs.coreutils}/bin/rm -r $homeFile
                    set deferredDirs (string split -n $file $deferredDirs)
                    set trackedFiles (string split -n $file $trackedFiles)
                    set invalidated true
                end
                continue
            end

            if [ -e $homeFile ]
                ${pkgs.coreutils}/bin/rm $homeFile
                set trackedFiles (string split -n $file $trackedFiles)
                set invalidated true
            end
        end
    end

    # untrack any deferred dirs which couldn't be removed.
    for dir in $deferredDirs
        set trackedFiles (string split -n $dir $trackedFiles)
        builtin set_color yellow
        ${pkgs.coreutils}/bin/echo The tracked directory $dir should have been removed but could not be because it contains untracked files.
        ${pkgs.coreutils}/bin/echo The directory has been untracked and must be manually managed from now on.
        builtin set_color normal
    end
end

for themeFile in (${pkgs.findutils}/bin/find $themeDir -type f)
    set -l file (string split -n -m1 $themeDir/ $themeFile)
    set -l homeFile $HOME/$file

    # ensure that parent directories exist and add any directories we make to tracked files list.
    set -l segments (string split / (${pkgs.coreutils}/bin/dirname $file))
    for i in (${pkgs.coreutils}/bin/seq (builtin count $segments))
        set -l dir (string join / $segments[(${pkgs.coreutils}/bin/seq $i)])
        set -l homeDir $HOME/$dir

        if [ ! -e $homeDir ]
            ${pkgs.coreutils}/bin/mkdir $homeDir
            set -a trackedFiles $dir
        end
    end

    ${pkgs.coreutils}/bin/cp --no-preserve=mode,ownership $themeFile $homeFile
    if [ -x $themeFile ]
        ${pkgs.coreutils}/bin/chmod +x $homeFile
    else
        ${pkgs.coreutils}/bin/chmod -x $homeFile
    end

    ! builtin contains $file $trackedFiles; and set -a trackedFiles $file
end

${pkgs.coreutils}/bin/mkdir -p $dataDir
${pkgs.coreutils}/bin/truncate -s 0 $trackedFilesFile
string join \n $trackedFiles > $trackedFilesFile
${pkgs.coreutils}/bin/echo $themeName > $activeThemeFile

set -U THEMENIX_THEME_NAME $themeName

${postInstall}
''

)
{
    usersDir = null;
    postInstallScripts = {};
}
