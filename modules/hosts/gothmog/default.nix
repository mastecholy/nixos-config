{ lib, ... }:
{
  # Desktop: AMD CPU + AMD GPU, two monitors.
  # Generate the report on gothmog with:
  #   sudo nix run nixpkgs#nixos-facter -- -o modules/hosts/gothmog/hardware_report.json
  hardware.facter.reportPath = lib.mkIf (builtins.pathExists ./hardware_report.json) ./hardware_report.json;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Load amdgpu in the initrd so the boot screen is at native resolution
  hardware.amdgpu.initrd.enable = true;

  # Unlocks clock/voltage/power-limit controls in LACT (amdgpu.ppfeaturemask);
  # takes effect after a reboot
  hardware.amdgpu.overdrive.enable = true;

  # Battle.net and other extras (modules/features/workstation/modules/gaming-extra)
  gaming.extra.enable = true;

  # Wake on LAN (`wake gothmog` from any host). Also needs "Wake on LAN" /
  # "Power on by PCI-E" enabled and ErP disabled in the BIOS.
  networking.interfaces.eno1.wakeOnLan.enable = true;
  # NetworkManager manages eno1 and would otherwise apply its own default
  networking.networkmanager.settings.connection."ethernet.wake-on-lan" = "magic";

  # Cap eno1 (Realtek 2.5G, r8169) at 1 Gbit/s: at 2.5G the link keeps
  # dropping on this network. r8169 resets the advertised speeds whenever
  # the interface comes up, so a .link file or ethtool at boot doesn't
  # stick; NetworkManager applies this on every connect instead (with
  # auto-negotiation on, speed + duplex advertise only that one mode).
  # Remove to go back to 2.5G.
  # networking.networkmanager.ensureProfiles.profiles.eno1 = {
  #   connection = {
  #     id = "eno1";
  #     type = "ethernet";
  #     interface-name = "eno1";
  #     # Preferred over NetworkManager's automatic "Wired connection 1"
  #     autoconnect-priority = 10;
  #   };
  #   ethernet = {
  #     auto-negotiate = true;
  #     speed = 1000;
  #     duplex = "full";
  #   };
  #   ipv4.method = "auto";
  #   ipv6.method = "auto";
  # };
}
