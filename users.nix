{ ... }:

{
  # Define a user account. Don't forget to set a password with ‘passwd’.
  # users.users.jane = {
  #   isNormalUser = true;
  #   extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
  # };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGoNERTKsysxLg10U5gR/u2bAEQ1FuqLcnm0ONsGTXw4 Joshua Gustafson"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC00AG0O5/puSgqVQeqL8e/no0NdqNrs6IET9OykhJZ+iDVK52WC+v48SZsNIHh+/3370JsSKB5FU3q0bkgFvMfk7cTg30K+yKjlamnsFn2fd/rhhO7Iadj9crD9To+LpNoiRDD0JOqPLHWXRiyOPrxBVgUvWfJptrGm0ZKtVu0rR629n5fU/l4WZZY6KAV8DvOSvRneChTLWtrAGTbSdpaDJs+ie2u9MvNULFGLbPFc1ZcPAYjlI2mewCsIRuMx4jZ3Zwn8SBa/F0idCj3SS32lZtGaDdg/iV52DrxFWhwNXI3sPAx8lem82+3Umx7blOB02whEFTrYBePPVgif3uod8k5GiNrOmAgfYbcAe7rSma+yUfujTBKtLqJogl+QGbi6gzGXkvsY3dc50nUVyDok7HFiY+HDeCdonv0iwSubG5BZD7EkqkJnDD+yvTZ/W5c+I/tYSh92x/4Mp/pnxHgguHSqZNbwAVFuR7ACfkRKSfWsr8qBP8bixpCaN+U//3UwIFJRKRbJCpO8r8v6sGF5X0yO660TcupzLOsW6qCjcVm1uOin06zcbILqyWb9CvnC/ufKH/IAKDbU3oRJELS6fwaMY/oAoSXqdlg9ABvwioVafPZkeK5thf8cpKySPd4hoxtilO3lTbxUccZsVnzkj86IxGmU95B//PLs5Ctcw== Joshua Gustafson"
  ];

  users.users.josh = {
    uid = 1001;
    isNormalUser = true;
    extraGroups = [ "wheel" "www" "docker" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGoNERTKsysxLg10U5gR/u2bAEQ1FuqLcnm0ONsGTXw4 Joshua Gustafson"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC00AG0O5/puSgqVQeqL8e/no0NdqNrs6IET9OykhJZ+iDVK52WC+v48SZsNIHh+/3370JsSKB5FU3q0bkgFvMfk7cTg30K+yKjlamnsFn2fd/rhhO7Iadj9crD9To+LpNoiRDD0JOqPLHWXRiyOPrxBVgUvWfJptrGm0ZKtVu0rR629n5fU/l4WZZY6KAV8DvOSvRneChTLWtrAGTbSdpaDJs+ie2u9MvNULFGLbPFc1ZcPAYjlI2mewCsIRuMx4jZ3Zwn8SBa/F0idCj3SS32lZtGaDdg/iV52DrxFWhwNXI3sPAx8lem82+3Umx7blOB02whEFTrYBePPVgif3uod8k5GiNrOmAgfYbcAe7rSma+yUfujTBKtLqJogl+QGbi6gzGXkvsY3dc50nUVyDok7HFiY+HDeCdonv0iwSubG5BZD7EkqkJnDD+yvTZ/W5c+I/tYSh92x/4Mp/pnxHgguHSqZNbwAVFuR7ACfkRKSfWsr8qBP8bixpCaN+U//3UwIFJRKRbJCpO8r8v6sGF5X0yO660TcupzLOsW6qCjcVm1uOin06zcbILqyWb9CvnC/ufKH/IAKDbU3oRJELS6fwaMY/oAoSXqdlg9ABvwioVafPZkeK5thf8cpKySPd4hoxtilO3lTbxUccZsVnzkj86IxGmU95B//PLs5Ctcw== Joshua Gustafson"
    ];
  };

  users.users.gustafson = {
    uid = 1000;
    isNormalUser = true;
  };
}
