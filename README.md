# NixOS

One flake for three machines: two Hyprland workstations and a home server,
with shared users, theming, secrets and tooling.

| Host      | Role        | Hardware                                         |
|-----------|-------------|--------------------------------------------------|
| `sihil`   | workstation | Laptop: Ryzen 7840HS + RTX 4060 (PRIME offload)  |
| `gothmog` | workstation | Desktop: Ryzen 9800X3D, AMD GPU, two monitors    |
| `nazgul`  | server      | Home server: NVMe system disk, 2× 8 TB btrfs RAID1 |

**Highlights:** Hyprland + [Noctalia](https://noctalia.dev) shell, system-wide
theming with [Stylix](https://github.com/nix-community/stylix), LazyVim,
fish/starship, secrets with [sops-nix](https://github.com/Mic92/sops-nix),
disk layout with [disko](https://github.com/nix-community/disko), hardware
detection with [nixos-facter](https://github.com/nix-community/nixos-facter),
and a self-hosted media server reachable only on the LAN and over Tailscale.

## Layout

```
flake.nix                    hosts, users and how each system is assembled
.sops.yaml                   who can decrypt secrets/secrets.yaml
secrets/secrets.yaml         encrypted secrets (sops)
modules/
  common/
    nixos-core/              every host: boot, nix, users, ssh, sops, nh, nx, wake
    disko/bare-ext4.nix      disk layout: ESP + swap + ext4 root
  features/
    workstation/             desktop role: Hyprland, audio, Steam, LACT, gaming-extra, ...
    server/                  server role: Docker for oci-containers
    home-manager/
      modules/cli/           every host: fish, git, ssh, neovim, btop
      modules/desktop/       workstations only: Hyprland, Noctalia, kitty, Firefox
      dotfiles/hypr/         Hyprland config (Lua)
  hosts/<name>/              per-machine config, facter hardware report, monitors
    nazgul/services/         homelab services (homelab.<service>.enable)
```

## How it fits together

`flake.nix` has a `hosts` attrset (role, stateVersion, time zone, GPU flags,
disk) and a `users.primary` entry. `mkHost` turns each host into a
`nixosConfiguration` from these modules, in order:

1. `modules/common/nixos-core/core.nix`: everything every machine gets
2. `modules/features/<role>/<role>.nix`: `workstation` or `server`
3. `modules/hosts/<name>/default.nix`: that machine only
4. Home Manager (`modules/features/home-manager`): `cli/` everywhere,
   `desktop/` on workstations
5. disko and sops-nix

Folders named `modules/` are loaded with
[import-tree](https://github.com/denful/import-tree): **any `.nix` file dropped
in is imported automatically**, so there are no import lists to maintain. Host
values (`hostName`, `role`, `hasNvidia`, `users`, ...) reach modules as
`specialArgs`, and reach Home Manager through `hmArgs`.

The config lives in `/etc/nixos` on every machine (owned by the primary user)
and is deployed with [nh](https://github.com/nix-community/nh).

## Everyday use

`nx` wraps the git + nh workflow and works from any directory:

| Command            | Does                                                          |
|--------------------|---------------------------------------------------------------|
| `nx`               | pull, then switch                                             |
| `nx test` / `boot` | pull, then `nh os test` / `nh os boot`                        |
| `nx sync "msg"`    | pull, commit everything, switch, push if the build worked     |
| `nx update`        | update flake inputs, switch, commit + push `flake.lock`       |
| `nx on <host>...`  | deploy what's pushed to other hosts over SSH                  |

Commits are GPG-signed, so `sync` and `update` run on the workstations. Other
helpers: `wake <host>` (Wake-on-LAN, relayed by the server, works over
Tailscale) and `organize-comics` on nazgul (sorts manga and comics into a
Komga layout).

## Secrets

All secrets and personal details (password hashes, name, email, location,
tokens) live encrypted in `secrets/secrets.yaml`. Each host decrypts with its
own SSH host key; `.sops.yaml` lists who can decrypt. Decrypted values only
exist at runtime under `/run/secrets`.

```fish
sops secrets/secrets.yaml                         # edit
sops set secrets/secrets.yaml '["key"]' '"value"'  # set one value
mkpasswd -m yescrypt                              # make a password hash
```

Keys the config expects:

| Key | Used by |
|---|---|
| `root_password_hash`, `user_password_hash` | login passwords (`mkpasswd` output) |
| `full_name`, `email` | git identity |
| `location` | Noctalia weather |
| `ssh_hosts` | extra private `~/.ssh/config` entries (may be just a comment) |
| `samba_password` | nazgul's SMB share, auto-mounted on workstations |
| `wol_hosts` | `<host> <mac>` lines for `wake` |
| `duckdns_token` | wildcard TLS certificate (server) |
| `protonvpn_wireguard_key` | gluetun VPN for qBittorrent (server) |
| `immich_db_password` | Immich database (server) |

## Adding a machine

1. Add it to `hosts` in `flake.nix` (role, disk, swap, GPU flags).
2. Create `modules/hosts/<name>/default.nix`; add `monitors.lua` for a
   workstation (see the others).
3. Boot the target from a NixOS installer, then from an existing machine
   generate its hardware report and install it with
   [nixos-anywhere](https://github.com/nix-community/nixos-anywhere). disko
   wipes the disk in `hosts.<name>.disko.storageDevice`:
   ```fish
   nix run github:nix-community/nixos-anywhere -- --flake .#<name> \
     --generate-hardware-config nixos-facter modules/hosts/<name>/hardware_report.json \
     root@<installer-ip>
   ```
   The report lists device serial numbers, which the config doesn't use;
   blank them before committing:
   ```fish
   nix shell nixpkgs#jq -c sh -c 'f=modules/hosts/<name>/hardware_report.json; jq "(.. | objects | select(has(\"serial\")) | .serial) |= \"\"" $f > $f.tmp && mv $f.tmp $f'
   ```
4. Let it read secrets: add its key to `.sops.yaml` (`ssh-keyscan <host> |
   ssh-to-age`), run `sops updatekeys secrets/secrets.yaml`, commit, and
   `nx on <name>`.
5. To SSH from it to the others, add its `~/.ssh/id_ed25519.pub` to
   `extraAuthorizedKeys` in `flake.nix`.

## Users

The config is built around one primary user (`users.primary` in `flake.nix`:
name, GPG key, SSH keys). Change those values to make it yours. Login
passwords come from sops, and `users.mutableUsers` is off, so the config is
the only source of accounts.

For another person, add an entry in `modules/common/nixos-core/modules/users.nix`
(and a password hash secret alongside the existing ones in `secrets.nix`):

```nix
users.users.alex = {
  isNormalUser = true;
  extraGroups = [ "networkmanager" ];
  hashedPasswordFile = config.sops.secrets.alex_password_hash.path;
};
```

Home Manager is set up for the primary user only. Give another user their own
`home-manager.users.<name>` if they need dotfiles.

## The server (nazgul)

Every service has a switch in `modules/hosts/nazgul/default.nix`
(`homelab.<service>.enable`) and a file in `services/`:

- **Media:** Jellyfin, Audiobookshelf, Calibre-Web (ebooks, OPDS), Komga
  (manga and comics, OPDS)
- **Photos:** Immich (containers)
- **Files:** File Browser, Samba (`smb://nazgul/data`)
- **Downloads:** qBittorrent behind gluetun (ProtonVPN WireGuard with port
  forwarding)
- **Access:** nginx at `<service>.<domain>` with one wildcard Let's Encrypt
  certificate via a DuckDNS DNS challenge. The domain points at the Tailscale
  IP, so nothing is exposed to the internet; a few ports (Jellyfin, OPDS,
  SMB) are opened on the wired LAN for devices without Tailscale.
- **Storage:** btrfs RAID1 at `/srv/data` with monthly scrubs and hourly
  btrbk snapshots of the irreplaceable subvolumes.
- **Updates:** native services follow nixpkgs (`nx update`); containers that
  track a tag are pulled weekly by `container-updates.timer`.

To add a service: create `services/<name>.nix` with a
`homelab.<name>.enable` option, import it in `services/default.nix`, add
`<name>.port = ...;` to `subdomains` in `services/proxy.nix`, and enable it.

## Making it your own

1. **Fork and rename:** change `users.primary` and `hosts` in `flake.nix`,
   and the folders in `modules/hosts/`. Delete hosts you don't need.
2. **Replace the secrets:** create your own age key
   (`age-keygen -o ~/.config/sops/age/keys.txt`), put your key and your hosts'
   keys in `.sops.yaml`, delete `secrets/secrets.yaml`, and create a new one
   with `sops secrets/secrets.yaml` using the keys listed above. Leave out
   the server ones if you drop the server.
3. **Check the few hard-coded names:**
   - `nazgul` as the Wake-on-LAN relay (`modules/common/nixos-core/modules/wake.nix`)
   - the share mount (`modules/features/workstation/modules/nazgul-share.nix`)
   - the host list in `modules/features/home-manager/modules/cli/ssh.nix`
   - `homelab.domain` and `homelab.lanInterface`
     (`modules/hosts/nazgul/services/default.nix`) and the LAN subnet in
     `torrent.nix`
4. **Taste:** colors in `modules/common/nixos-core/modules/stylix.nix`,
   keybinds in `modules/features/home-manager/dotfiles/hypr/`, the bar in
   `noctalia.nix`.
5. **Install** each machine as in [Adding a machine](#adding-a-machine).

Workstation-only niceties (`gaming.extra.enable`, LACT, the Samba
auto-mount) are opt-in or easy to delete. A host without the `server` role
never pulls in any homelab code.
