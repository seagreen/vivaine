# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let
  escoger = pkgs.haskellPackages.callPackage ./extended-nixpkgs/escoger { };

in let
  unstableTarball = builtins.fetchGit {
    url = https://github.com/nixos/nixpkgs/;
    # `git ls-remote https://github.com/nixos/nixpkgs-channels nixos-unstable`
    rev = "0a7e258012b60cbe530a756f09a4f2516786d370";
  };
in {

  nixpkgs.config = {
    packageOverrides = pkgs: {
      unstable = import unstableTarball {
        config = config.nixpkgs.config;
      };
    };
  };

  ############################################################
  # Applications
  ############################################################

  nixpkgs.config.allowUnfree = true;

  # Anything that would require changes to this file in more
  # than one place or has other files associated with it gets
  # factored out to become an import.
  imports = [

    # Window manager
    ./src/xmonad/c.nix

    # Terminal
    ./src/urxvt/c.nix

    # Text editors
    ./src/emacs/c.nix
    ./src/vim/c.nix

    # Email
    ./src/mbsync/c.nix # IMAP client
    ./src/mutt/c.nix
    ./src/msmtp/c.nix # SMTP client

    ./src/firefox/c.nix
    ./src/git/c.nix
    ./src/haskell/c.nix
    ./src/networking/c.nix
    ./src/virtualbox/c.nix

    # NOTE: Not version controlled.
    ./nginx.nix
  ];

  # List packages installed in system profile.
  environment.systemPackages = with pkgs; [
    unstable.stack
    unstable.haskellPackages.cabal-install
    unstable.sqlint
    unstable.haskellPackages.stylish-haskell

    unstable.alacritty
    anki
    ascii
    cloc
    cool-retro-term
    # unstable.dhall-text
    docker_compose
    dropbox
    elmPackages.elm
    # escoger
    evince
    fasd
    fd
    feh
    file
    fish
    ffmpeg # Dep of youtubeDL
    fzf
    gnome3.eog
    gnome3.file-roller # Archive manager with a GUI.
    gnome3.gedit
    gnome3.nautilus # file manager
    (gnupg.override { pinentry = pinentry; })
    gnumake
    google-chrome
    gparted
    graphviz # Provides the `dot` executable.
    haskellPackages.bench
    # haskellPackages.steeloverseer
    haskellPackages.una # CLI archive manager with a sweet UI.
    htop
    httpie
    i3lock
    imagemagick
    jq
    libreoffice
    lynx
    mnemosyne
    mosh
    mplayer # Required for my weechat beep command.
    # mumble
    # newsbeuter
    nix-repl # Basic use: nix-repl '<nixos>'
    nmap
    nodejs
    nodePackages.npm
    notmuch
    pandoc
    pass
    # Configure PulseAudio.
    # Run and mess with the settings here if the computer isn't picking up your mic.
    pavucontrol
    pciutils # for lspci
    gnuplot
    pwgen
    python27
    python27Packages.ipython
    redis
    rsync
    shotwell
    signal-desktop
    silver-searcher
    speedtest_cli
    stdenv # Includes `gcc` for C programming
    stow
    telnet
    tmux
    # Pandoc doesn't allow outputing of .pdfs without this as a dep. See here:
    #     https://nixos.org/wiki/TexLive_HOWTO
    #
    # Removed simply because is was building slow:
    # (texLiveAggregationFun { paths = [ texLive texLiveExtra texLiveBeamer lmodern ]; })
    (transmission.override { enableGTK3 = true;})
    tree
    unzip # Needed for una.
    vlc
    weechat
    wget
    xclip # Let pass access the clipboard.
    xorg.xhost # for graphical docker
    xournal # Edit pdfs. inkscape can only work on single pages.
    xvidcap # Video screenshots
    youtubeDL # ffmpeg is a dep if used with "--audio-format vorbis"
    zathura
  ];

  # NOTE: changes to this take effect on login.
  environment.sessionVariables = {
    EDITOR = "nvim";

    NIXPKGS_ALLOW_UNFREE = "1";

    # Don't create .pyc files.
    PYTHONDONTWRITEBYTECODE = "1";
  };

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql94;
    port = 5432; # Make the default explicit.

    # pg_hba.conf
    authentication = pkgs.lib.mkForce ''
      local all all           trust
      host  all all localhost trust
    '';
  };

  virtualisation.docker.enable = true;

  ############################################################
  # Infrastructure
  ############################################################

  nix.nixPath = [
    # Use our own nixpkgs clone. A guide to doing so is here:
    # http://anderspapitto.com/posts/2015-11-01-nixos-with-local-nixpkgs-checkout.html
    #
    # In nixpkgs (modified from the linked article):
    # git remote add channels https://github.com/nixos/nixpkgs-channels
    # git fetch channels
    # git checkout channels/nixos-unstable
    "nixpkgs=/home/traveller/code/nixpkgs"

    # Keep the default nixos-config:
    "nixos-config=/etc/nixos/configuration.nix"
  ];

  # X11 windowing system.
  services.xserver = {
    enable = true;

    desktopManager.default = "none";

    # The display manager "provides a graphical login prompt and
    # manages the X server" (from the NixOS manual).
    displayManager.lightdm.enable = true;

    # xset m sets mouse sensativity (acceleration/threshold).
    displayManager.sessionCommands = ''
      sh /home/traveller/.fehbg &
      xmobar                    &
      xset mouse 10 2           &
      dropbox                   &
    '';

    layout = "us";
    xkbOptions = "caps:super"; # setxkbmap settings:
  };

  # Select internationalisation properties.
  i18n = {
    consoleFont = "lat9w-16";
    consoleKeyMap = "us";
    defaultLocale = "en_US.UTF-8";
  };

  hardware.pulseaudio = {
    enable = true;
    package = pkgs.pulseaudioFull;
  };

  # Use ulimit to prevent runaway programs from freezing the computer.
  #
  # View ulimit settings with `ulimit -a`.
  #
  # Test if this is working with:
  #
  #     `echo "a = []\nwhile True: a.append(' ' * 50)" | python`
  #
  # NOTE: Changes take effect on login.
  security.pam.loginLimits = [{
    domain = "*";
    type = "hard";
    item = "as";
    value = "4000000";
  }];

  services.redshift = {
    enable = true;
    # http://jonls.dk/redshift/
    #
    # When you specify a location manually, note that a location south of equator
    # has a negative latitude and a location west of Greenwich (e.g the Americas)
    # has a negative longitude.
    latitude = "35";
    longitude = "-90"; # Actually about -82, but I wanted redshift to start later.
    temperature = {
      day = 5500;
      night = 2500;
    };
  };
  # Sudden restarts aren't fun on the eyes.
  systemd.services.redshift.restartIfChanged = false;

  # Enable ssh-add. On by default.
  programs.ssh = {
    startAgent = true;
    agentTimeout = null; # Keep keys in memory forever.
  };

  services.openvpn.servers = {
    # systemctl start openvpn-east
    east = {
      config = ''
        cd /home/traveller/code/nixnotes/vpn
        config "/home/traveller/code/nixnotes/vpn/US East.ovpn"
      '';
      autoStart = false;
    };
  };

  # This doesn't seem to work:
  networking.enableIPv6 = false;
  # This works via /proc/sys/net/ipv6/conf/all/disable_ipv6
  boot.kernel.sysctl."net.ipv6.conf.all.disable_ipv6" = true;

  time.timeZone = "America/New_York";
  services.ntp = {
    enable = true;
    servers = [ "server.local" "0.pool.ntp.org" "1.pool.ntp.org" "2.pool.ntp.org" ];
  };

  # Unfortunately this makes password management tricky. See here:
  #
  #     https://github.com/NixOS/nixpkgs/issues/3788
  #
  # users.mutableUsers = false;

  security.sudo.wheelNeedsPassword = false;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.extraUsers.traveller = {
    name = "traveller";
    group = "users";
    extraGroups = [ "wheel" "docker" ];
    uid = 1000;
    home = "/home/traveller";
    createHome = true;
    shell = "/bin/sh"; # Changes to this take effect on login.
    openssh.authorizedKeys.keyFiles = [
      "/home/traveller/.ssh/id_rsa.pub"
    ];
  };
}
