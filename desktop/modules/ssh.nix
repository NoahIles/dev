{identity, ...}: {
  services.openssh = {
    enable = true;
    ports = [2222];
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  users.users.${identity.username}.openssh.authorizedKeys.keys = identity.sshKeys;
}
