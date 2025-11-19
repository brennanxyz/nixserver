{ config, lib, pkgs, ... }:

# need secrets across the config
let
  secrets = import "/etc/nixos/secrets.nix";
in
{
  # import hardware config
  imports = [
    ./hardware-configuration.nix
  ];

  # boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  # activate zsh
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      noe = "sudo hx /etc/nixos";
      nors = "sudo nixos-rebuild switch";
    };
  };
  environment.pathsToLink = [ "/share/zsh" ];

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
    xclip
  ];

  # TODO: configure helix, install xclip and traefik, make aliases
  system.stateVersion = "25.05";
}
