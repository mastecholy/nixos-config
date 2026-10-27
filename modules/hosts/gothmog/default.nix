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
  # dropping on this network. Only the first .link file that matches a NIC
  # applies, so this one also carries what it would otherwise shadow:
  # systemd's default naming (99-default.link) and Wake-on-LAN. Matched by
  # PCI slot (see hardware_report.json). Remove to go back to 2.5G.
  systemd.network.links."10-eno1" = {
    matchConfig.Path = "pci-0000:0a:00.0";
    linkConfig = {
      NamePolicy = "keep kernel database onboard slot path";
      AlternativeNamesPolicy = "database onboard slot path";
      MACAddressPolicy = "persistent";
      WakeOnLan = "magic";
      Advertise = "10baset-full 100baset-full 1000baset-full";
    };
  };
}
