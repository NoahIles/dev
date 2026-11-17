# Samba, moved from docker CT 110 (servercontainers/samba, 4.22). Globals and
# shares follow 110's `testparm -s`. The passdb (smbpasswd) is state: imported
# from 110 with pdbedit, never in the repo.
#  - mp0: /Pool-1/media at /media (the Media share)
#  - mp1: /Pool-1/timemachine at /timemachine (dataset, quota 500G)
_: {
  imports = [../../modules/media.nix];

  users.users.noah = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = ["media_share"];
  };

  services.samba = {
    enable = true;
    openFirewall = true;
    nmbd.enable = false; # clients connect by address; Macs browse via avahi below
    settings = {
      global = {
        "server role" = "standalone server";
        security = "user";
        "passdb backend" = "smbpasswd";
        "map to guest" = "Bad User";
        "load printers" = "no";
        "printcap name" = "/dev/null";
        "smb1 unix extensions" = "no";
        "mangled names" = "no";
        "vfs objects" = "catia fruit streams_xattr";
        "fruit:aapl" = "yes";
        "fruit:model" = "TimeCapsule";
        "fruit:encoding" = "native";
        "fruit:locking" = "netatalk";
        "fruit:metadata" = "stream";
        "fruit:resource" = "file";
      };
      Media = {
        path = "/media";
        "valid users" = "noah";
        "read only" = "no";
        # New files group-writable for the *arrs (media-state-swap.md, option C).
        "force group" = "media_share";
        "create mask" = "0664";
        "directory mask" = "2775";
      };
      TimeMachine = {
        path = "/timemachine/%U";
        "valid users" = "noah";
        "read only" = "no";
        "posix locking" = "no";
        "fruit:time machine" = "yes";
        "fruit:time machine max size" = "500G";
      };
    };
  };

  systemd.tmpfiles.rules = ["d /timemachine/noah 0700 noah users -"];

  # Advertised as the host name ("samba"), so the build doesn't clash with
  # 110's "StorageServer" while both run.
  services.avahi = {
    enable = true;
    openFirewall = true;
    publish.enable = true;
    publish.userServices = true;
    extraServiceFiles.timemachine = ''
      <?xml version="1.0" standalone='no'?>
      <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
      <service-group>
        <name replace-wildcards="yes">%h</name>
        <service><type>_smb._tcp</type><port>445</port></service>
        <service><type>_device-info._tcp</type><port>0</port><txt-record>model=TimeCapsule</txt-record></service>
        <service>
          <type>_adisk._tcp</type>
          <txt-record>sys=waMa=0,adVF=0x100</txt-record>
          <txt-record>dk0=adVN=TimeMachine,adVF=0x82</txt-record>
        </service>
      </service-group>
    '';
  };

  system.stateVersion = "26.05";
}
