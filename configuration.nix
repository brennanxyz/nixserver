{ config, lib, pkgs, ... }:

# need secrets across the config
let
  secrets = import "/etc/nixos/secrets.nix";
in
{
  # import hardware config and home manager
  imports = [
    ./hardware-configuration.nix
    (builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/release-25.05.tar.gz" + "/nixos")
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
      nod = "cd /etc/nixos";
      xc = "xclip -selection clipboard";
    };
  };
  environment.pathsToLink = [ "/share/zsh" ];

  # allow ssh connections
  services.openssh.enable = true;

  # configure root account
  users.users.root = {
    shell = pkgs.zsh;
  };
  
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
    "d /etc/nixos/.git 0775 brenn brenn -"
    "d /etc/nixos/.git/object 0775 brenn brenn -"
  ];

  # install packages
  environment.systemPackages = with pkgs; [
    git
    helix
    xclip
  ];

  # home manager config
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  # root home config 
  home-manager.users.root = { pkgs, ...}: {
    home.stateVersion = "25.05";
    
    home.file.".config/helix/config.toml".text = ''
      theme = "gruvbox-dark"

      [editor]
      line-number = "relative"

      [editor.file-picker]
      git-ignore = false
    '';
  };

  # brenn home config
  home-manager.users.brenn = { pkgs, ...}: {
    home.stateVersion = "25.05";
    
    home.file.".config/helix/config.toml".text = ''
      theme = "gruvbox-dark"

      [editor]
      line-number = "relative"

      [editor.file-picker]
      git-ignore = false
    '';
  };

  # traefik
  virtualisation.docker = {
    enable = true;
  };

  users.groups.traefik = {};
  users.users.traefik = {
    isSystemUser = true;
    group = "traefik";
    extraGroups = [ "docker" ];
  };
  
  # TODO: install traefik
  # https://github.com/aksiksi/compose2nix
  system.stateVersion = "25.05";
}
