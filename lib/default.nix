pkgs:

{
    hosts = import ./hosts.nix pkgs;
    themes = import ./themes.nix pkgs;
    trivial = import ./trivial.nix pkgs;
}
