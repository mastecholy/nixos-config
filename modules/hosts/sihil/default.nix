{ ... }:
{
  # Lenovo Legion Slim 5 14APH8: Ryzen 7 7840HS (Radeon 780M) + RTX 4060 Laptop
  hardware.facter.reportPath = ./hardware_report.json;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  gaming.extra.enable = true;

  services.xserver.videoDrivers = [ "nvidia" ];

  # Goodix fingerprint reader
  services.fprintd.enable = true;

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    # Lets the dGPU power off when idle; requires PRIME offload
    powerManagement.finegrained = true;

    # Open kernel modules are recommended for Turing and newer (RTX 4060 is Ada)
    open = true;
    nvidiaSettings = true;

    # Run apps on the dGPU with `nvidia-offload <cmd>`
    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      amdgpuBusId = "PCI:5:0:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };
}
