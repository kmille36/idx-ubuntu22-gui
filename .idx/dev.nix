{ pkgs, ... }: {
  # Use a recent channel (matches Firebase Studio docs)
  channel = "stable-24.11";

  # Tools available in the terminal
  packages = [
    pkgs.docker
    pkgs.cloudflared
  ];

  # Enable Docker (rootless)
  services.docker.enable = true;

  # Auto-run your container on workspace start
  idx.workspace.onStart = {
    novnc = ''
      # Be forgiving on rebuilds
      docker start ubuntu-novnc 
      

      docker run --name ubuntu-novnc \
        --shm-size 1g -d \
        -p 8080:10000 \
        -e VNC_PASSWD=password \
        -e PORT=10000 \
        -e AUDIO_PORT=1699 \
        -e WEBSOCKIFY_PORT=6900 \
        -e VNC_PORT=5900 \
        -e SCREEN_WIDTH=1024 \
        -e SCREEN_HEIGHT=768 \
        -e SCREEN_DEPTH=24 \
        thuonghai2711/ubuntu-novnc-pulseaudio:22.04
        rm -rf /home/*
        cloudflared tunnel --url http://localhost:8080
    '';
  };

  # (Optional) show a preview tile in the UI – the app already runs via onStart,
  # so we just keep a harmless long-lived command.
  idx.previews = {
    enable = true;
    previews = {
      novnc = {
        command = [ "bash" "-lc" "echo 'noVNC on port 8080'; tail -f /dev/null" ];
        manager = "web";
      };
    };
  };
}
