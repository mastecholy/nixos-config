{ inputs, ... }:
{
  imports = [
    (inputs.import-tree ./modules)
  ];

  services.xserver = {
    enable = true;
    xkb.options = "caps:swapescape";
  };
}
