{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.virtualisation.multipass;
  multipass = pkgs.libsForQt5.callPackage ./package.nix {};
in
  with lib; {
    options = {
      virtualisation.multipass = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = lib.mdDoc ''
            This option enables multipass, a daemon that manages
            virtualised Ubuntu instances with a simple command
            line interface.
          '';
        };

        logLevel = mkOption {
          type = types.str;
          default = "debug";
          description = lib.mdDoc ''
            The logging verbosity of the multipassd binary.

            Options are <error|warning|info|debug|trace>
          '';
        };

        package = mkOption {
          type = types.package;
          default = multipass;
          description = lib.mdDoc ''
            The multipass package to use
          '';
        };
      };
    };

    config = lib.mkIf cfg.enable {
      environment.systemPackages = [cfg.package];

      systemd.services.multipass = {
        description = "Multipass orchestrates virtual Ubuntu instances";

        wantedBy = ["multi-user.target"];
        wants = ["network.target"];
        after = ["network.target"];

        environment = {
          "XDG_DATA_HOME" = "/var/lib/multipass/data";
          "XDG_CACHE_HOME" = "/var/lib/multipass/cache";
          "XDG_CONFIG_HOME" = "/var/lib/multipass/config";
        };

        serviceConfig = {
          ExecStart = "${cfg.package}/bin/multipassd --logger platform --verbosity ${cfg.logLevel}";
          SyslogIdentifer = "multipassd";
          Restart = "on-failure";
          TimeoutStopSec = 300;
          Type = "simple";

          WorkingDirectory = "/var/lib/multipass";

          StateDirectory = "multipass";
          StateDirectoryMode = "0750";
          CacheDirectory = "multipass";
          CacheDirectoryMode = "0750";
        };
      };
    };
  }
