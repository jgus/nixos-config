{ ... }:

{
  users = {
    groups.plex = { gid = 193; };
    users.plex = {
      uid = 193;
      isSystemUser = true;
      group = "plex";
    };
  };
}
