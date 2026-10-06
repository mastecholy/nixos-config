{
  description = "Choly's NixOS flake based on Nucleus Architecture.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    import-tree.url = "github:denful/import-tree";
    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lazyvim = {
      url = "github:pfassina/lazyvim-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      disko,
      sops-nix,
      ...
    }@inputs:
    let
      inherit (nixpkgs) lib;

      # !=== HOSTS DEFINITION ===!
      # Each attribute name is the host name; host-specific modules live in
      # ./modules/hosts/<name>/ (default.nix, monitors.lua, hardware_report.json).
      # role selects the feature set: "workstation" (desktop) or "server".
      hosts = {
        # Laptop: Lenovo Legion Slim 5 14APH8
        sihil = {
          role = "workstation";
          stateVersion = "26.05";
          timeZone = "America/New_York";
          hasNvidia = true;
          # Hybrid graphics (AMD iGPU + NVIDIA dGPU) using PRIME offload
          nvidiaPrime = true;
          disko = {
            storageDevice = "/dev/nvme0n1";
            swapSize = "8G";
          };
        };

        # Desktop: all-AMD, two monitors
        gothmog = {
          role = "workstation";
          stateVersion = "26.05";
          timeZone = "America/New_York";
          hasNvidia = false;
          nvidiaPrime = false;
          disko = {
            # Single 2 TB NVMe (confirmed with lsblk); wiped on install
            storageDevice = "/dev/nvme0n1";
            swapSize = "16G";
          };
        };

        # Home server: Docker Compose services, 2x 8 TB RAID1 data array
        nazgul = {
          role = "server";
          stateVersion = "26.05";
          timeZone = "America/New_York";
          hasNvidia = false;
          nvidiaPrime = false;
          disko = {
            # 256 GB NVMe system disk; the data HDDs are sda/sdb and are never
            # touched by disko
            storageDevice = "/dev/nvme0n1";
            swapSize = "4G";
          };
        };
      };

      # !=== USERS DEFINITION ===!
      # Passwords, name, email and other personal details live encrypted in
      # secrets/secrets.yaml (see modules/common/nixos-core/modules/secrets.nix)
      users = {
        primary = {
          userName = "mas";
          gpgKey = "40C18590181960C36A3DD6D518F24E40864FE613";
          # sihil's key
          sshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEIZMZ+hqxHSKoHgdcjS/jba9FPcDu07SW78nngU+NQV";
          # Public keys of other machines allowed to SSH in, in addition to sshKey
          extraAuthorizedKeys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGUhXTc4Xt0SmeNPMM8PBxPNL0sgBkJ3ECTZ7AP9zJZ8 mas@gothmog"
            # Termius on Android
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL56It/xySLDZRTbkyWVWDG9GuseKUg/0b1hkv/EltRb mas@android"
          ];
        };
      };

      # !=== ENVIRONMENT CONFIG ===!
      configDirectory = "/etc/nixos/";

      mkHost =
        hostName: host:
        let
          reportPath = ./modules/hosts/${hostName}/hardware_report.json;
          hostArgs = {
            inherit hostName;
            inherit (host)
              role
              stateVersion
              timeZone
              hasNvidia
              nvidiaPrime
              ;
            inherit (host.disko) storageDevice swapSize;
          };
        in
        lib.nixosSystem {
          # Taken from the facter report once it exists for the host
          system =
            if builtins.pathExists reportPath then
              (builtins.fromJSON (builtins.readFile reportPath)).system
            else
              "x86_64-linux";
          specialArgs = hostArgs // {
            inherit
              inputs
              configDirectory
              users
              ;
            # !=== HOME MANAGER ===!
            hmArgs = {
              inherit (users.primary)
                userName
                gpgKey
                ;
              inherit (host) role hasNvidia nvidiaPrime;
              inherit hostName;
            };
          };
          modules = [
            ./modules/common/nixos-core/core.nix
            ./modules/features/${host.role}/${host.role}.nix
            ./modules/hosts/${hostName}/default.nix
            home-manager.nixosModules.home-manager
            ./modules/features/home-manager/decl.nix
            disko.nixosModules.disko
            sops-nix.nixosModules.sops
            ./modules/common/disko/bare-ext4.nix
          ];
        };
    in
    {
      nixosConfigurations = lib.mapAttrs mkHost hosts;
      diskoConfigurations = lib.mapAttrs (
        _: host: import ./modules/common/disko/bare-ext4.nix host.disko
      ) hosts;
    };
}
