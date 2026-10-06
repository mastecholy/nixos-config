{
  # ly's PAM service substacks "login", which already gets gnome-keyring
  # (services.gnome.gnome-keyring) and fingerprint auth (services.fprintd).
  security.rtkit.enable = true;
}
