{ config, pkgs, ... }: (import ./zwave-js-ui.nix) { inherit config pkgs; area = "main"; }
