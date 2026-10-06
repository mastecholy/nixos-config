{ config, lib, ... }:
let
  cfg = config.homelab.immich;
  inherit (config.sops) placeholder;
  docker = "${config.virtualisation.docker.package}/bin/docker";
  network = "immich";
  state = "/var/lib/immich";
  library = "${config.homelab.photos}/immich";
  tz = config.time.timeZone;
in
{
  options.homelab.immich = {
    enable = lib.mkEnableOption "Immich (containers)";
    version = lib.mkOption {
      type = lib.types.str;
      default = "v3";
      description = ''
        Immich image tag. A major-version tag follows that major's releases
        (picked up by ./updates.nix); move to the next major by hand after
        reading its release notes. The database was migrated off pgvecto.rs
        on v2, which v3 requires.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.immich_db_password = { };
    sops.templates = {
      "immich.env".content = "DB_PASSWORD=${placeholder.immich_db_password}\n";
      "immich-postgres.env".content = "POSTGRES_PASSWORD=${placeholder.immich_db_password}\n";
    };

    virtualisation.oci-containers.backend = "docker";
    virtualisation.oci-containers.containers =
      let
        common = {
          networks = [ network ];
          environment.TZ = tz;
        };
        immichEnv = {
          TZ = tz;
          DB_HOSTNAME = "immich_postgres";
          DB_USERNAME = "postgres";
          DB_DATABASE_NAME = "immich";
          REDIS_HOSTNAME = "immich_redis";
        };
      in
      {
        immich_postgres = common // {
          # Includes VectorChord plus pgvecto.rs for migrating older databases
          image = "ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0";
          environment = {
            POSTGRES_USER = "postgres";
            POSTGRES_DB = "immich";
            POSTGRES_INITDB_ARGS = "--data-checksums";
          };
          environmentFiles = [ config.sops.templates."immich-postgres.env".path ];
          volumes = [ "${state}/postgres:/var/lib/postgresql/data" ];
          extraOptions = [ "--shm-size=128m" ];
        };

        immich_redis = common // {
          image = "docker.io/valkey/valkey:9";
        };

        immich_server = common // {
          image = "ghcr.io/immich-app/immich-server:${cfg.version}";
          pull = "always";
          environment = immichEnv;
          environmentFiles = [ config.sops.templates."immich.env".path ];
          ports = [ "127.0.0.1:2283:2283" ];
          volumes = [
            "${library}:/data"
            # Path used by older releases; keeps stored asset paths valid
            "${library}:/usr/src/app/upload"
            "/etc/localtime:/etc/localtime:ro"
          ];
          # Intel Quick Sync / VA-API for video transcoding
          extraOptions = [ "--device=/dev/dri:/dev/dri" ];
          dependsOn = [
            "immich_postgres"
            "immich_redis"
          ];
        };

        immich_machine_learning = common // {
          image = "ghcr.io/immich-app/immich-machine-learning:${cfg.version}";
          pull = "always";
          environment = immichEnv;
          environmentFiles = [ config.sops.templates."immich.env".path ];
          volumes = [ "${state}/model-cache:/cache" ];
          # The server looks for http://immich-machine-learning:3003 by default
          extraOptions = [ "--network-alias=immich-machine-learning" ];
        };
      };

    systemd.tmpfiles.rules = [
      "d ${state} 0750 root root -"
      "d ${state}/model-cache 0750 root root -"
    ];

    # Private network for the Immich containers (they find each other by name)
    systemd.services = {
      "docker-network-${network}" = {
        description = "Create the ${network} Docker network";
        after = [ "docker.service" ];
        requires = [ "docker.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = "${docker} network inspect ${network} >/dev/null 2>&1 || ${docker} network create ${network}";
      };
    }
    //
      lib.genAttrs
        (map (c: "docker-${c}") [
          "immich_postgres"
          "immich_redis"
          "immich_server"
          "immich_machine_learning"
        ])
        (_: {
          after = [ "docker-network-${network}.service" ];
          requires = [ "docker-network-${network}.service" ];
        });
  };
}
