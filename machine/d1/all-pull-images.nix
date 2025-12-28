args@{ lib, ... }:
let
  # Read the services directory
  servicesDir = ./../../services;
  serviceFiles = builtins.readDir servicesDir;

  # Get all .nix files
  nixFiles = builtins.filter
    (
      name:
      serviceFiles.${name} == "regular"
      && lib.strings.hasSuffix ".nix" name
      && !(lib.strings.hasPrefix "." name)
    )
    (builtins.attrNames serviceFiles);

  # Helper to extract docker.pullImage from a service definition
  getPullImage = service:
    if (service ? docker && service.docker ? pullImage) then [ service.docker.pullImage ] else [ ];

  # Process a single service file
  pullImagesInFile = name:
    let
      contents = import (servicesDir + "/${name}") args;
      pullImages =
        if (lib.isList contents) then
          (lib.concatMap getPullImage contents)
        else
          (getPullImage contents);
    in
    map (i: { pullImage = i; file = name; }) pullImages;
in
lib.concatMap pullImagesInFile nixFiles
