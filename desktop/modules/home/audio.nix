{...}: {
  xdg.configFile."pipewire/pipewire.conf.d/99-rodecaster-virtual-sinks.conf".source =
    ../../configs/pipewire/99-rodecaster-virtual-sinks.conf;
  xdg.configFile."pipewire/pipewire.conf.d/90-app-routing.conf".source =
    ../../configs/pipewire/90-app-routing.conf;
}
