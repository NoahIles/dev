{
  services.openssh = {
    enable = true;
    ports = [2222];
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  users.users.noah.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL1ZB2LANb2hD3MHbLLmwqbc/8UkV3IPvWgK/Jm4ZhtO Noahiles@gmail.com"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK4h69x56lUT7AUubYN5mw7hwGOaXE7Bjcl8wzyiRyiI noah@cachyos-island"
  ];
}
