{ config, lib, ... }:
let
  cfg = config.homelab;

  # <name>.<domain> -> local port
  subdomains = {
    jelly.port = 8096;
    audiobooks.port = 13378;
    files.port = 8888;
    qbit.port = 8085;
    books = {
      port = 8083;
      # Book uploads through the web UI
      extraConfig = "client_max_body_size 500M;";
    };
    komga.port = 25600;
    immich = {
      port = 2283;
      # Large uploads and long-running requests from the mobile app
      extraConfig = ''
        client_max_body_size 50000M;
        proxy_read_timeout 600s;
        proxy_send_timeout 600s;
        send_timeout 600s;
      '';
    };
  };
in
{
  options.homelab.reverseProxy.enable = lib.mkEnableOption "nginx with a wildcard certificate for *.<domain>";

  config = lib.mkIf cfg.reverseProxy.enable {
    sops.secrets.duckdns_token = { };

    # One wildcard certificate for every subdomain, issued through a DuckDNS
    # DNS challenge so nothing has to be reachable from the internet. Renews
    # automatically.
    security.acme = {
      acceptTerms = true;
      certs.${cfg.domain} = {
        domain = "*.${cfg.domain}";
        dnsProvider = "duckdns";
        dnsResolver = "1.1.1.1:53";
        credentialFiles.DUCKDNS_TOKEN_FILE = config.sops.secrets.duckdns_token.path;
        group = config.services.nginx.group;
      };
    };

    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;

      virtualHosts = lib.mapAttrs' (
        name: s:
        lib.nameValuePair "${name}.${cfg.domain}" {
          forceSSL = true;
          useACMEHost = cfg.domain;
          locations."/" = {
            proxyPass = "http://127.0.0.1:${toString s.port}";
            proxyWebsockets = true;
          };
          extraConfig = s.extraConfig or "";
        }
      ) subdomains;
    };

    # LAN and Tailscale; nothing is forwarded from the internet
    networking.firewall.allowedTCPPorts = [
      80
      443
    ];
  };
}
