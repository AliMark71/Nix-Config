{
    description = "nix-darwin system flake";

    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
        nix-darwin.url = "github:LnL7/nix-darwin";
        nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
        nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    };

    outputs = _inputs@{ self, nix-darwin, nixpkgs, nix-homebrew }:
        let
            configuration = { pkgs, config, lib, ... }: {
                # List packages installed in system profile. To search by name, run:
                # $ nix-env -qaP | grep wget

                nixpkgs.config.allowUnfree = true;

                environment.systemPackages = lib.lists.flatten (with pkgs; [
                    asciiquarium cloudflared curl
                    clang cmake fd ffmpeg gcc14
                    go gh gnupg mkvtoolnix neofetch
                    neovim ninja obsidian pnpm
                    python3 pinentry_mac ripgrep
                    rustup speedtest-cli wget

                    (with lua51Packages; [
                        lua luarocks
                    ])

                    # ghostty-bin
                    moonlight-qt raycast 
                    tailscale warp-terminal

                    # NIX DLCs
                    [
                        otesunki-try
                        otesunki-rmunzip
                    ]
                ]);

                homebrew = {
                    enable = true;
                    brews = [
                        "mas"
                    ];
                    casks = ["Kegworks-App/kegworks/kegworks" "ghostty"];
                    masApps = {};
                    onActivation.cleanup = "zap";
                    onActivation.autoUpdate = true;
                    onActivation.upgrade = true;
                };

                system.primaryUser = "ali";
                system.defaults = {
                    NSGlobalDomain = {
                        InitialKeyRepeat                 = 15;
                        KeyRepeat                        = 2;
                        "com.apple.trackpad.scaling"     = 1.71;
                        "com.apple.trackpad.forceClick"  = true;
                        "com.apple.swipescrolldirection" = false;
                    };
                    menuExtraClock = {
                        Show24Hour  = true;
                        ShowSeconds = true;
                    };
                    trackpad = {
                        Clicking             = true;
                        FirstClickThreshold  = 0;
                        SecondClickThreshold = 0;
                    };
                };

                security.pam.services.sudo_local = {
                     enable = true;
                     touchIdAuth = true;
                    #watchIdAuth = true;
                };

                nixpkgs.overlays = [
                    (self: super: {
                        otesunki-try = super.stdenv.mkDerivation rec {
                            pname = "otesunki-try";
                            version = "2.1";
                            nativeBuildInputs = [];
                            buildInputs = [];
                            installPhase = ''
                                mkdir -p $out/bin
                                cp $src $out/bin/try
                            '';
                            src = super.writeShellScript "try.sh" ''
                                nix shell "github:NixOS/nixpkgs/nixpkgs-unstable#$1" --command "$@"
                            '';
                            dontUnpack = true;
                            dontBuild = true;
                            dontConfigure = true;
                            dontPatch = true;
                            dontFixup = true;
                        };
                        otesunki-rmunzip = super.stdenv.mkDerivation rec {
                            pname = "otesunki-rmunzip";
                            version = "1.0";
                            nativeBuildInputs = [];
                            buildInputs = [];
                            installPhase = ''
                                mkdir -p $out/bin
                                cp $src $out/bin/rmunzip
                            '';
                            src = super.writeShellScript "rmunzip.sh" ''
                                unzip -qql "$*" | while read -r l d t n ; do rm -fr "$n" ; done
                            '';
                            dontUnpack = true;
                            dontBuild = true;
                            dontConfigure = true;
                            dontPatch = true;
                            dontFixup = true;
                        };
                    })
                ];

                # Necessary for using flakes on this system.
                nix.settings.experimental-features = "nix-command flakes";

                # Enable alternative shell support in nix-darwin.
                programs.zsh.enable = true;
                # programs.fish.enable = true;

                # Set Git commit hash for darwin-version.
                system.configurationRevision = self.rev or self.dirtyRev or null;

                # Used for backwards compatibility, please read the changelog before changing.
                # $ darwin-rebuild changelog
                system.stateVersion = 5;

                # The platform the configuration will be used on.
                nixpkgs.hostPlatform = "aarch64-darwin";
            };
        in
            {
            # Build darwin flake using:
            # $ darwin-rebuild build --flake .#DarwinPro
            darwinConfigurations."DarwinPro" = nix-darwin.lib.darwinSystem {
                modules = [
                    configuration
                    nix-homebrew.darwinModules.nix-homebrew
                    {
                        nix-homebrew = {
                            enable = true;
                            enableRosetta = true;
                            user = "ali";
                            autoMigrate = true;
                        };
                    }
                ];
            };
        };
}
