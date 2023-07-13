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

argparse "u/user=" -- $argv

set -l targetUser $argv[1]
set -l themeName $argv[2]

set -l sourceUser
if set -q _flag_user
    set sourceUser $_flag_user
else if [ -e ${usersDir}/$targetUser ]
    set sourceUser $targetUser
else if [ -e ${usersDir}/default ]
    set sourceUser default
else
    builtin exit
end

set -l targetHomeDir (${pkgs.getent}/bin/getent passwd $targetUser | ${pkgs.coreutils}/bin/cut -d : -f 6)
set -l targetXdgDataHome (${pkgs.su}/bin/su -s ${pkgs.bash}/bin/bash -c "${pkgs.coreutils}/bin/echo $XDG_DATA_HOME" - $targetUser)
[ -n "$targetXdgDataHome" ]; or set targetXdgDataHome $targetHomeDir/.local/share

set -l targetDataDir $targetXdgDataHome/themenix
set -l trackedFilesFile $targetDataDir/tracked_files
set -l activeThemeFile $targetDataDir/active_theme

set -l sourceDir (${pkgs.coreutils}/bin/realpath ${usersDir}/$sourceUser/themes/$themeName)
set -l trackedFiles
[ -e $trackedFilesFile ]; and set trackedFiles (${pkgs.coreutils}/bin/cat $trackedFilesFile)

if [ (builtin count $trackedFiles) -gt 0 ]
    set -l deferredDirs

    set -l invalidated true
    while [ $invalidated = true ]
        set invalidated false

        for file in $trackedFiles
            set -l targetFile $targetHomeDir/$file
            set -l sourceFile $sourceDir/$file

            [ -e $sourceFile ]; and continue

            if [ ! -e $targetFile ]
                # Tracked file has already been removed. remove from tracked files list.
                set trackedFiles (string split -n $file $trackedFiles)
                continue
            end

            if [ -d $targetFile ]
                if [ -n "$(${pkgs.coreutils}/bin/ls -A $targetFile)" ]
                    # Dir contains files. Defer removal.
                    ! builtin contains $file $deferredDirs; and set -a deferredDirs $file
                else
                    # Dir is empty. Free to rm.
                    ${pkgs.coreutils}/bin/rm -r $targetFile
                    set deferredDirs (string split -n $file $deferredDirs)
                    set trackedFiles (string split -n $file $trackedFiles)
                    set invalidated true
                end
                continue
            end

            if [ -e $targetFile ]
                ${pkgs.coreutils}/bin/rm $targetFile
                set trackedFiles (string split -n $file $trackedFiles)
                set invalidated true
            end
        end
    end

    # Untrack any deferred dirs which couldn't be removed.
    for dir in $deferredDirs
        set trackedFiles (string split -n $dir $trackedFiles)
        builtin set_color yellow
        ${pkgs.coreutils}/bin/echo The tracked directory $dir should have been removed but could not be because it contains untracked files.
        ${pkgs.coreutils}/bin/echo The directory has been untracked and must be manually managed from now on.
        builtin set_color normal
    end
end

for sourceFile in (${pkgs.findutils}/bin/find $sourceDir -type f)
    set -l file (string split -n -m1 $sourceDir/ $sourceFile)
    set -l targetFile $targetHomeDir/$file

    # Ensure that parent directories exist and add any directories we make to tracked files list.
    set -l segments (string split / (${pkgs.coreutils}/bin/dirname $file))
    for i in (${pkgs.coreutils}/bin/seq (builtin count $segments))
        set -l dir (string join / $segments[(${pkgs.coreutils}/bin/seq $i)])
        set -l targetDir $HOME/$dir

        if [ ! -e $targetDir ]
            ${pkgs.coreutils}/bin/mkdir $targetDir
            set -a trackedFiles $dir
        end
    end

    ${pkgs.coreutils}/bin/cp --no-preserve=mode,ownership $sourceFile $targetFile
    if [ -x $sourceFile ]
        ${pkgs.coreutils}/bin/chmod +x $targetFile
    else
        ${pkgs.coreutils}/bin/chmod -x $targetFile
    end

    ! builtin contains $file $trackedFiles; and set -a trackedFiles $file
end

${pkgs.coreutils}/bin/mkdir -p $targetDataDir
${pkgs.coreutils}/bin/truncate -s 0 $trackedFilesFile
string join \n $trackedFiles > $trackedFilesFile
${pkgs.coreutils}/bin/echo $themeName > $activeThemeFile

${pkgs.su}/bin/su -c ${postInstall} - $targetUser
''

)
{
    usersDir = null;
    postInstallScripts = {};
}
