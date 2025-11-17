{ config, pkgs, ... }:

# need secrets across the config
let
  secrets = import "/etc/nixos/secrets.nix";
in
{
  imports = [ <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-minimal-combined.nix> ];

  # activate zsh
  programs.zsh.enable = true;

  # allow ssh connections
  services.openssh.enable = true;
  
  # make user account
  users.groups.brenn = {};
  users.users.brenn = {
    isNormalUser = true;
    group = "brenn";
    extraGroups = [ "wheel"];
    openssh.authorizedKeys.keys = [
      secrets.brenn_ssh_key
    ];
    shell = pkgs.zsh;
    home = "/home/brenn";
    createHome = true;
  };
  
  # allow user config permissions
  systemd.tmpfiles.rules = [
    "d /etc/nixos 0775 brenn brenn -"
  ];

  # install packages
  environment.systemPackages = with pkgs; [
    helix
  ];

  # TODO: configure helix, install xclip and traefik, make aliases  
}
