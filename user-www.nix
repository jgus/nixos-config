{ ... }:

{
  users = {
    groups.www = { gid = 911; };
    users.www = {
      uid = 911;
      isSystemUser = true;
      group = "www";
    };
  };
}
