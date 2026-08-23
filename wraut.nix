{ config, pkgs, ... }:

let
  wraut-service = pkgs.stdenv.mkDerivation {
    # get wraut from GH releases
    pname = "wraut";
    version = "0.0.1";

    src = pkgs.fetchurl {
      url = "https://github.com/brennanxyz/wraut/releases/download/0.0.3/wraut";
      sha256 = "7bd40b185471102fd7e40e35174bdc0edc4370bf2fa034a36eee086e9736f94b";
    };

    dontUnpack = "true";

    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/wraut
      chmod +x $out/bin/wraut
    '';
  };

  initDb = pkgs.fetchurl {
    url = "https://github.com/brennanxyz/wraut/releases/download/0.0.3/wraut.db";
    sha256 = "20fa9d636f3c174978209b5e7663a48e38c0372dfa79bd639b684e6156d9df59";
  };
in
{
  # Create a dedicated user for wraut
  users.users.wraut-user = {
    isSystemUser = true;
    group = "wraut-user";
    extraGroups = [ "docker" ];  # Add to docker group for Docker access
  };

  users.groups.wraut-user = {};

  systemd.services.wraut-service = {
    description = "Wraut CI/CD";
    wantedBy =  [ "multi-user.target" ];
    after = [ "network.target" "docker.service" ];
    requires = [ "docker.service" ];

    serviceConfig = {
      ExecStart = "${wraut-service}/bin/wraut";
      Restart = "on-failure";
      User = "wraut-user";
      Group = "wraut-user";
      StateDirectory = "wraut";
      StateDirectoryMode = "0750";
      SupplementaryGroups = [ "docker" ];
      Path = [ pkgs.docker ];
      ExecStartPre = "+" + (pkgs.writeShellScript "wraut-setup" ''
        if [ ! -f /var/lib/wraut/wraut.db ]; then
          echo "Installing initial Wraut database..."
          ${pkgs.coreutils}/bin/cp ${initDb} /var/lib/wraut/wraut.db
          ${pkgs.coreutils}/bin/chmod 0640 /var/lib/wraut/wraut.db
        fi

        # Create directories
        ${pkgs.coreutils}/bin/mkdir -p /var/lib/wraut/git
        ${pkgs.coreutils}/bin/mkdir -p /var/lib/wraut/live
        ${pkgs.coreutils}/bin/mkdir -p /var/lib/wraut/logs
        ${pkgs.coreutils}/bin/mkdir -p /var/lib/wraut/fs
      
        # Set ownership
        ${pkgs.coreutils}/bin/chown -R wraut-user:wraut-user /var/lib/wraut
        ${pkgs.coreutils}/bin/chmod 1777 /var/lib/wraut/fs
      '');
      Environment = [
        "PATH=${pkgs.docker}/bin:${pkgs.coreutils}/bin"
        "DB_URL=%S/wraut/wraut.db"
        "DATABASE_URL=sqlite://%S/wraut/wraut.db"
        "APP_HOST=0.0.0.0"
        "APP_PORT=3000"
        "LOGS_PATH=%S/wraut/logs"
        "SERVICE_REPO_PATH=%S/wraut/git"
        "SERVICE_LIVE_PATH=%S/wraut/live"
        "KEY_FILE=/home/brenn/.ssh/id_ed25519"
      ];
    };
  };
}
