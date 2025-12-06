{ config, pkgs, ... }:
let
  secrets = import "/etc/nixos/secrets.nix";
in
{
  # enable Docker
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
  };

  # user
  users.groups.traefik = {};
  users.users.traefik = {
    isSystemUser = true;
    group = "traefik";
    extraGroups = [ "docker" ];
  };

  # traefik direct oci config
  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      traefik = {
        image = "docker.io/library/traefik:v3.5.2";
        ports = [
          "80:80"
          "443:443"
          "8080:8080"
        ];
        volumes = [
          # mount Docker socket for auto-discovery
          "/var/run/docker.sock:/var/run/docker.sock:ro"
          # configuration file (static config)
          "/etc/traefik/traefik.yml:/etc/traefik/traefik.yml:ro"
          # dynamic configuration directory
          "/etc/traefik/dynamic:/etc/traefik/dynamic:ro"
          # et's Encrypt certificates storage
          "/var/lib/traefik/acme.json:/acme.json"
        ];
        cmd = [
          "--configFile=/etc/traefik/traefik.yml"
        ];
        labels = {
          "traefik.enable" = "true";
          "traefik.http.routers.dashboard.rule" = "Host(`traefik.daxharris.com`)";
          "traefik.http.routers.dashboard.service" = "api@internal";
          "traefik.http.routers.dashboard.middlewares" = "auth";
          "traefik.http.middlewares.auth.basicauth.users" = secrets.traefik_creds;
          "traefik.http.routers.dashboard.tls"="true";
          "traefik.http.routers.dashboard.tls.certresolver" = "letsencrypt";
          "traefik.http.services.api.loadbalancer.server.port" = "8080";
        };
      };
    };
  };
  
  systemd.tmpfiles.rules = [
    "d /etc/traefik 0755 root root -"
    "d /etc/traefik/dynamic 0755 root root -"
    "d /var/lib/traefik 0755 root root -"
    "f /var/lib/traefik/acme.json 0600 root root -"
    "d /var/log/traefik 0755 root root -"
  ];

  environment.etc."traefik/traefik.yml".text = ''
    api:
      insecure: false
      dashboard: true
    entryPoints:
      web:
        address: ":80"
        http:
          redirections:
            entryPoint:
              to: websecure
              scheme: https

      websecure:
        address: ":443"
        http:
          tls:
            certResolver: letsencrypt

    certificatesResolvers:
      letsencrypt:
        acme:
          email: brennan@brennanharris.xyz
          storage: /acme.json
          httpChallenge:
            entryPoint: web

    providers:
      docker:
        endpoint: "unix:///var/run/docker.sock"
        exposedByDefault: false
        network: host
    
      file:
        directory: /etc/traefik/dynamic
        watch: true

    log:
      filePath: "/etc/traefik/traefik.log"
      format: json
      level: INFO
  
    accessLog: {}
  '';
  networking.firewall.allowedTCPPorts = [ 80 443 8080 ];
}
