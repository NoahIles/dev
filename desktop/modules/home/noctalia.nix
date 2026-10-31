{config, ...}: {
  # Fully declarative noctalia settings. The module renders `settings` to
  # ~/.config/noctalia/config.toml (store-backed, validated at build time with
  # `noctalia config validate`). Noctalia merges every *.toml in that dir, then
  # overlays ~/.local/state/noctalia/settings.toml on top: GUI edits land
  # there and WIN over this file until removed. Move that file aside after
  # switching if you want this to be authoritative.
  # Left out on purpose: config_version and the wallpaper rotation's
  # current picks (wallpaper.last, wallpaper.monitors.*) are runtime state;
  # location.address and a battery device serial don't belong in a public repo.
  programs.noctalia = {
    enable = true;
    # Runs noctalia as a user unit (Restart=on-failure, own journal) instead
    # of niri's spawn-at-startup.
    systemd.enable = true;
    settings = {
      theme = {
        mode = "dark";
        templates = {
          user = {
            helium = {
              input_path = "helium-theme.json";
              output_path = "\$XDG_CACHE_HOME/noctalia/helium-theme/manifest.json";
            };
          };
          builtin_ids = [
            "alacritty"
            "btop"
            "cava"
            "gtk3"
            "gtk4"
            "ghostty"
            "helix"
            "kcolorscheme"
            "niri"
            "qt"
            "scroll"
            "starship"
            "wezterm"
          ];
          community_ids = [
            "opencode"
            "zen-browser"
            "discord"
            "neovim"
            "obsidian"
            "vscode"
            "zed"
            "prismlauncher"
            "steam"
            "fuzzel"
            "zathura"
            "hyprtoolkit"
            "bat"
            "lazygit"
            "yazi"
          ];
        };
        builtin = "m3-content";
        community_palette = "Rosey AMOLED";
        custom_palette = "ADW";
        pure_black_dark = true;
        wallpaper_scheme = "vibrant";
      };
      accessibility = {
        ui_scale = 1.15;
      };
      audio = {
        enable_overdrive = true;
      };
      backdrop = {
        enabled = true;
      };
      bar = {
        default = {
          background_opacity = 0.0;
          center = ["clock" "status" "bar_2"];
          end = [
            "tray"
            "media"
            "battery"
            "group:g1"
            "volume"
            "brightness"
            "session"
            "bar"
          ];
          margin_edge = 1;
          padding = 6;
          scale = 1.1;
          shadow = false;
          start = ["launcher" "wallpaper" "workspaces" "active_window"];
          widget_spacing = 22;
          capsule_group = [
            {
              accordion = false;
              accordion_direction = "end";
              enabled = true;
              fill = "surface_variant";
              id = "g1";
              members = ["notifications" "clipboard" "bluetooth"];
              opacity = 1.0;
              padding = 6.0;
            }
          ];
        };
      };
      battery = {
        device = {
          "/org/freedesktop/UPower/devices/battery_hidpp_battery_0" = {
            warning_threshold = 25;
          };
        };
      };
      brightness = {
        enable_ddcutil = true;
      };
      desktop_widgets = {
        schema_version = 1;
        widget_order = ["desktop-widget-0000000000000002" "desktop-widget-0000000000000001" "desktop-widget-0000000000000003"];
        grid = {
          cell_size = 24;
          major_interval = 4;
          visible = true;
        };
        widget = {
          desktop-widget-0000000000000001 = {
            box_height = 96.0;
            box_width = 384.0;
            cx = 3208.0;
            cy = 1392.0;
            output = "DP-1";
            placement_height = 1440.0;
            placement_width = 3440.0;
            rotation = 0.0;
            type = "audio_visualizer";
            settings = {
              background = false;
              bands = 32;
              show_when_idle = true;
            };
          };
          desktop-widget-0000000000000002 = {
            box_height = 848.0;
            box_width = 1104.0;
            cx = 232.0;
            cy = 280.0;
            output = "DP-1";
            placement_height = 1440.0;
            placement_width = 3440.0;
            rotation = 0.0;
            type = "fancy_audio_visualizer";
            settings = {
              background = false;
              bar_width = 0.5;
              bloom_intensity = 1.0;
              fade_when_idle = true;
              inner_diameter = 0.55;
              ring_opacity = 0.1;
              rotation_speed = 0.0;
              sensitivity = 0.8;
              visualization_mode = "bars";
              wave_thickness = 0.4;
            };
          };
          desktop-widget-0000000000000003 = {
            box_height = 96.0;
            box_width = 168.0;
            cx = 106.0;
            cy = 1362.55;
            output = "DP-1";
            placement_height = 1440.0;
            placement_width = 3440.0;
            rotation = 0.0;
            type = "sysmon";
            settings = {
              background = false;
              shadow = false;
              show_label = true;
              stat = "cpu_usage";
            };
          };
        };
      };
      dock = {
        active_monitor_only = true;
        active_scale = 1.25;
        background_opacity = 1.0;
        cross_axis_padding = 6;
        enabled = false;
        icon_size = 44;
        inactive_opacity = 0.9;
        launcher_position = "end";
        magnification_scale = 2.0;
        main_axis_padding = 8;
        margin_edge = 0;
        position = "right";
        shadow = false;
      };
      idle = {
        behavior_order = ["lock" "screen-off" "suspend"];
        behavior = {
          lock = {
            action = "lock";
            enabled = true;
            timeout = 600.0;
          };
          screen-off = {
            action = "screen_off";
            enabled = true;
            timeout = 660.0;
          };
          suspend = {
            action = "lock_and_suspend";
            enabled = true;
            timeout = 900.0;
          };
        };
      };
      lockscreen = {
        allow_empty_password = true;
      };
      lockscreen_widgets = {
        enabled = false;
        schema_version = 2;
        widget_order = ["lockscreen-login-box@DP-1" "lockscreen-login-box@DP-2"];
        grid = {
          cell_size = 16;
          major_interval = 4;
          visible = true;
        };
        widget = {
          "lockscreen-login-box@DP-1" = {
            box_height = 196.0;
            box_width = 810.0;
            cx = 1720.0;
            cy = 1317.0;
            output = "DP-1";
            placement_height = 1440.0;
            placement_width = 3440.0;
            rotation = 0.0;
            type = "login_box";
            settings = {
              center_password_text = false;
              layout = "regular";
              show_caps_lock = true;
              show_keyboard_layout = true;
              show_login_button = true;
              show_media = true;
              show_password_reveal = true;
              show_session_buttons = true;
              show_unlock_hint = true;
              show_weather = true;
            };
          };
          "lockscreen-login-box@DP-2" = {
            box_height = 196.0;
            box_width = 810.0;
            cx = 1280.0;
            cy = 1317.0;
            output = "DP-2";
            placement_height = 1440.0;
            placement_width = 2560.0;
            rotation = 0.0;
            type = "login_box";
            settings = {
              center_password_text = false;
              layout = "regular";
              show_caps_lock = true;
              show_keyboard_layout = true;
              show_login_button = true;
              show_media = true;
              show_password_reveal = true;
              show_session_buttons = true;
              show_unlock_hint = true;
              show_weather = true;
            };
          };
        };
      };
      nightlight = {
        enabled = true;
        temperature_night = 5000;
      };
      notification = {
        scale = 1.25;
      };
      plugin_settings = {
        "lowcache/claude-companion" = {
          sessions_open_near_click = true;
        };
      };
      plugins = {
        enabled = [
          "felipeartur/ai-usagebar"
          "lowcache/claude-companion"
          "cleboost/zed-provider"
          "noahiles/zerotier"
          "raycursive/discord-voice"
        ];
        source = [
          {
            kind = "git";
            location = "https://github.com/noctalia-dev/official-plugins";
            name = "official";
          }
          {
            kind = "git";
            location = "https://github.com/noctalia-dev/community-plugins";
            name = "community";
          }
          {
            kind = "path";
            location = "${config.home.homeDirectory}/Documents/noctalia-zerotier";
            name = "local";
          }
        ];
      };
      shell = {
        clipboard_history_max_entries = 200;
        font_family = "SF Pro Text";
        lang = "en";
        niri_overview_type_to_launch_enabled = true;
        password_style = "random";
        polkit_agent = true;
        settings_show_advanced = false;
        telemetry_enabled = false;
        time_format = "{:%-I:%M %p}";
        launcher = {
          app_grid = true;
          category_icons_only = true;
        };
        panel = {
          control_center_placement = "floating";
          open_near_click_control_center = true;
          transparency_mode = "glass";
        };
        screenshot = {
          copy_to_clipboard = true;
          directory = "${config.home.homeDirectory}/Pictures/Screenshots";
          freeze_screen = true;
        };
      };
      wallpaper = {
        directory = "${config.home.homeDirectory}/Pictures/UW_Wallpapers";
        per_monitor_directories = true;
        automation = {
          enabled = true;
          # ponytail: unknown key to noctalia (schema has interval_seconds), so
          # carried over as-is from settings.toml and ignored, same as before.
          interval_minutes = 180;
        };
        default = {
          path = "${config.home.homeDirectory}/Pictures/UW_Wallpapers/UltrawideWallpapersDotNet-2266.jpeg";
        };
        monitor = {
          DP-1 = {
            directory = "${config.home.homeDirectory}/Pictures/UW_Wallpapers";
          };
          DP-2 = {
            directory = "${config.home.homeDirectory}/Pictures/UHD_Wallpapers";
          };
        };
        favorite = [
          {
            path = "${config.home.homeDirectory}/Pictures/UW_Wallpapers/uw_cherry_blossom.jpg";
            theme_mode = "dark";
          }
          {
            path = "${config.home.homeDirectory}/Pictures/UW_Wallpapers/UltrawideWallpapersDotNet-2266.jpeg";
          }
        ];
      };
      weather = {
        # ponytail: unknown here (the real key is location.auto_locate); ignored.
        auto_locate = true;
        unit = "imperial";
      };
      widget = {
        active_window = {
          capsule = true;
          max_length = 550;
          title_scroll = "always";
        };
        bar = {
          type = "felipeartur/ai-usagebar:bar";
        };
        bar_2 = {
          capsule = true;
          hide_when_disconnected = true;
          type = "raycursive/discord-voice:bar";
        };
        battery = {
          capsule = true;
          capsule_fill = "#000000";
          device = "/org/freedesktop/UPower/devices/battery_hidpp_battery_0";
          display_mode = "none";
        };
        bongocat = {
          audio_spectrum = true;
          input_device = "";
          script = "scripts/bongocat.lua";
          tappy_mode = true;
          type = "scripted";
        };
        brightness = {
          capsule = true;
          scale = 0.85;
        };
        clock = {
          capsule = true;
          format = "{:%-I:%M %p}";
          tooltip_format = "{:%A}, {:%h %d}";
        };
        custom_button_2 = {
          label = "asdf";
          type = "custom_button";
        };
        launcher = {
          capsule = true;
        };
        media = {
          album_art_only = true;
          art_size = 26;
          hide_when_no_media = true;
        };
        network = {
          scale = 0.8;
          show_label = false;
        };
        status = {
          type = "noahiles/zerotier:status";
        };
        tray = {
          drawer = true;
        };
        volume = {
          capsule = true;
          scale = 0.85;
        };
      };
    };
  };
  # Apps opened from the launcher land in this unit's cgroup; some (jellyfin-
  # desktop) ignore SIGTERM and stalled every reboot for the 90s default.
  systemd.user.services.noctalia.Service.TimeoutStopSec = "5s";
}
