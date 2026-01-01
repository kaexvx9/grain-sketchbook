# NixOS Configuration for Framework 16 Development Environment
# Based on Framework 16 Virtualization Strategy Recommendation

{ config, pkgs, ... }:

{
  # Enable networking
  networking.hostName = "nixos-vm";
  networking.networkmanager.enable = true;

  # Enable SSH access
  services.openssh.enable = true;
  services.openssh.permitRootLogin = "yes"; # For initial setup, change later
  services.openssh.passwordAuthentication = true; # For initial setup

  # Set your user (adjust as needed)
  users.users.xy = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    initialPassword = "changeme"; # Change on first login
    openssh.authorizedKeys.keys = [
      # Add your SSH public key here
      # "ssh-ed25519 ..."
    ];
  };

  # Enable sudo for wheel group
  security.sudo.wheelNeedsPassword = false;

  # Development tools
  environment.systemPackages = with pkgs; [
    # Zig compiler
    zig
    
    # Git and version control
    git
    git-lfs
    
    # Build tools
    gnumake
    cmake
    gcc
    binutils
    pkg-config
    
    # Utilities
    curl
    wget
    vim
    nano
    htop
    tree
    
    # NixOS tools
    nixos-option
    nixos-rebuild
  ];

  # Use Linux kernel 6.18.2 for better Framework 16 hardware support
  # Newer kernel provides better AMD support, performance, and features
  boot.kernelPackages = pkgs.linuxPackages_6_18;

  # Enable virtualization (for nested Alpine Linux if needed later)
  # Note: For AMD (Framework 16), nested virtualization may need special setup
  # virtualisation.libvirtd.enable = true;
  # boot.kernelParams = [ "kvm-amd.nested=1" ];

  # Set timezone (adjust as needed)
  time.timeZone = "America/Los_Angeles";

  # System state version
  system.stateVersion = "25.11";
}

