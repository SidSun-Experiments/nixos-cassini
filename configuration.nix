# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:
let
  home-manager = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/release-24.05.tar.gz";
in
{
  imports =
    [ # Include the results of the hardware scan.
      (import "${home-manager}/nixos")
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # Define additional supported filesystems
  boot.supportedFilesystems = [ "zfs" ];
  # Use ZFS compatible kernel packages
  boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
  # This is enabled by default for backwards compatibility purposes, but it is highly recommended to disable this option, as it bypasses some of the safeguards ZFS uses to protect your ZFS pools.
  boot.zfs.forceImportRoot = false;
  boot.zfs.extraPools = [ "immich" "general-pool" "reserve-pool" ];

  networking.hostName = "cassini"; # Define your hostname.
  # Define ZFS required host id - generated by:
  # head -c 8 /etc/machine-id
  networking.hostId = "533f7567";
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  # Define bridge network interface
  networking.bridges.br0.interfaces = ["enp8s0"];
  networking.interfaces.br0 = {
    useDHCP = true;
  };


  # Set your time zone.
  # time.timeZone = "Europe/Amsterdam";
  time.timeZone = "Asia/Kolkata";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  # Enable the X11 windowing system.
  # services.xserver.enable = true;


  # Enable the GNOME Desktop Environment.
  # services.xserver.displayManager.gdm.enable = true;
  # services.xserver.desktopManager.gnome.enable = true;
  

  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # hardware.pulseaudio.enable = true;
  # OR
  # services.pipewire = {
  #   enable = true;
  #   pulse.enable = true;
  # };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.libinput.enable = true;

  programs.fish.enable = true;
  users.defaultUserShell = pkgs.fish;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.sids = {
    isNormalUser = true;
    extraGroups = [ "docker" "libvirtd" ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
      #fish
    ];
  };
  home-manager.users.sids = {
    /* The home.stateVersion option does not have a default and must be set */
    home.stateVersion = "24.05";
    /* Here goes the rest of your home-manager config, e.g. home.packages = [ pkgs.foo ]; */
      home.packages = [
        (pkgs.python3.withPackages (ppkgs: [
          ppkgs.cryptography
        ]))
      ];
  };
  # Rey and Nick users
  users.users.nick = {
    isNormalUser = true;
    extraGroups = [ "docker" ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
      #fish
    ];
  };
  users.users.rewant = {
    isNormalUser = true;
    extraGroups = [ "docker" ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
      #fish
    ];
  };

  # Allow users to run mount and unmount
  # Backup scripts will need to mount / unmount ZFS snapshots
  # which reminds me, ZFS snapshot, destroy, mount and create permissions are given to sids via:
  # zfs allow sids snapshot,destroy,mount,create <zpool>
  security.sudo = {
    enable = true;
    extraRules = [{
      commands = [
        {
          command = "/run/wrappers/bin/mount";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/run/wrappers/bin/umount";
          options = [ "NOPASSWD" ];
        }
      ];
      groups = [ "users" ];
    }];
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    bat
    unzip
    btop
    lshw
    htop
    git
    restic
    rclone
    python3Full
    python3Packages.pip
    python3Packages.argcomplete
    python3Packages.virtualenv
    python3Packages.setuptools-rust
    tmux
    tree
    wget
    dig
    inetutils
    virt-manager
    silver-searcher
    mdadm
    zfs
    powertop
    # shc # shell script compiler, bookmarking if needed later
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "server";
    extraUpFlags = "--advertise-routes 10.42.0.0/16";
  };
  # BTRFS (boot disk) services
  services.btrfs.autoScrub.enable = true;
  services.btrfs.autoScrub.interval = "weekly";
  # ZFS services
  services.zfs.autoScrub.enable = true;
  services.zfs.trim.enable = true;
  # Cron
  services.cron = {
    enable = true;
    systemCronJobs = [
      "00 6,18 * * *      root    . /etc/profile; /root/backup-scripts/restic-backup.sh"
    ];
  };

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      PasswordAuthentication = false;
      AllowUsers = [ "root" "sids" "nick" "rewant" ]; # Allows all users by default. Can be [ "user1" "user2" ]
      PermitRootLogin = "prohibit-password"; # "yes", "without-password", "prohibit-password", "forced-commands-only", "no"
    };
  };
  # Enable Prometheus Exporters for monitoring
  services.prometheus.exporters = {
    node = {
      enable = true;
    };
    zfs = {
      enable = true;
    };
    # process.enable = true;
  };
  services.cadvisor = {
    enable = true;
    port = 9180;
    listenAddress = "0.0.0.0";
  };

  # Optimize and GC nix generations automatically
  nix.optimise.automatic = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };


  # Docker
  virtualisation = {
    docker = {
      enable = true;
      daemon = {
        settings = {
          "experimental" = true;
          "ipv6" = true;
          "ip6tables" = true;
          "fixed-cidr-v6" = "2001:db8:1::/64";
        };
      };
    };
    libvirtd = {
      enable = true;
      # Used for UEFI boot of Home Assistant OS guest image
      qemu.ovmf.enable = true;
    };
  };

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 80 443 ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  systemd.services."docker" = {
    preStart = "${pkgs.stdenv.shell} -c \'(while ! ${pkgs.tailscale.out}/bin/tailscale status > /dev/null 2>&1; do echo \"Waiting for tailscale to start...\"; sleep 2; done); sleep 2\'";
  };

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "24.05"; # Did you read the comment?

}

