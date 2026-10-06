{
  services = {
    power-profiles-daemon.enable = true;
    upower.enable = true;
    udisks2.enable = true;
    gnome.gnome-keyring.enable = true;
    gvfs.enable = true;
    pulseaudio.enable = false;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
    displayManager.ly.enable = true;
    libinput.enable = true;
    pcscd.enable = true;
    # GPU monitoring, fan curves, undervolting/overclocking. Settings are
    # made in the LACT app and kept per machine in /etc/lact/config.yaml
    # (services.lact.settings is left unset so the file stays writable)
    lact.enable = true;
  };
}
