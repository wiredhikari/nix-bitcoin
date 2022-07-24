{ config, lib, pkgs, ... }:

with lib;
let
  options.services.fedimint-gateway = {
      enable = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Enable Fedimint-Gateway,connects fedimint and lightning network.
      '';
    }; 
    address = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "Address to listen for RPC connections.";
    };
    port = mkOption {
      type = types.port;
      default = 5001;
      description = "Port to listen for RPC connections.";
    };
    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/fedimint-gateway";
      description = "The data directory for fedimint-gateway.";
    };
    user = mkOption {
      type = types.str;
      default = "fedimint-gateway";
      description = "The user as which to run fedimint-gateway.";
    };
    group = mkOption {
      type = types.str;
      default = cfg.user;
      description = "The group as which to run fedimint-gateway.";
    };
    nodes = {
      clightning = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable the clightning node interface.";
        };  
      };
    };  
    package = mkOption {
      type = types.package;
      default = config.nix-bitcoin.pkgs.minimint;
      defaultText = "config.nix-bitcoin.pkgs.minimint";
      description = "The package providing minimint binaries.";
    };
  };

  cfg = config.services.fedimint-gateway;
  nbLib = config.nix-bitcoin.lib;
  nbPkgs = config.nix-bitcoin.pkgs;
  runAsUser = config.nix-bitcoin.runAsUserCmd;
  secretsDir = config.nix-bitcoin.secretsDir;
  bitcoind = config.services.bitcoind;

in {
  inherit options;
  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
    services.bitcoind = {
      enable = true;
      txindex = true;
    };
    services.clightning.enable = true;
    systemd.tmpfiles.rules = [
      "d '${cfg.dataDir}' 0770 ${cfg.user} ${cfg.group} - -"
    ];
    systemd.services.fedimint-gateway = {
      wantedBy = [ "multi-user.target" ];
      requires = [ "minimint.service" "clightning.service" ];
      after = [ "minimint.service" "clightning.service" ];
      preStart = ''
        echo "auth = \"${bitcoind.rpc.users.public.name}:$(cat ${secretsDir}/bitcoin-rpcpassword-public)\"" \
          > fedimint-gateway.toml
      '';
      serviceConfig = nbLib.defaultHardening // {
      WorkingDirectory = cfg.dataDir;
      ExecStart = ''
      lightningd --network regtest --bitcoin-rpcuser=bitcoin --bitcoin-rpcpassword=bitcoin --lightning-dir=$FM_LN1_DIR --addr=127.0.0.1:9000 --plugin=$FM_BIN_DIR/ln_gateway --minimint-cfg=$FM_CFG_DIR &
      '';
      User = cfg.user;
      Group = cfg.group;
      Restart = "on-failure";
      RestartSec = "10s";
      ReadWritePaths = cfg.dataDir;
      };
    };
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      extraGroups = [ "bitcoinrpc-public" ];
    };
    users.groups.${cfg.group} = {};
    nix-bitcoin.operator.groups = [ cfg.group ];
  };
}
