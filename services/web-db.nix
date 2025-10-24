{ ... }:
{
  name = "web-db";
  configStorage = false;
  extraStorage = [ "web_db_data" ];
  requires = [ "var-lib-web_db_data.mount" ];
  docker = {
    image = "mysql:5.7";
    volumes = storagePath: [ "${storagePath "web_db_data"}:/var/lib/mysql" ];
  };
}
 