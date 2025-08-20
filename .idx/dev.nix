{ pkgs, ... }: {
  channel = "stable-24.11";
  
  packages = [
    pkgs.docker
    pkgs.cloudflared
    pkgs.socat
  ];

  services.docker.enable = true;

  idx.workspace.onStart = {
    novnc = ''
      set -e
      # One-time cleanup
      [ ! -f /home/user/.cleanup_done ] && rm -rf /home/user/.gradle/* /home/user/.emu/* && \
      find /home/user -mindepth 1 -maxdepth 1 ! -name 'idx-ubuntu22-gui' ! -name '.*' -exec rm -rf {} + && \
      touch /home/user/.cleanup_done

      # Start or run container
      if ! docker ps -a --format '{{.Names}}' | grep -qx 'ubuntu-novnc'; then
        docker run --name ubuntu-novnc \
          --shm-size 1g -d \
          --cap-add=SYS_ADMIN \
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
      else
        docker start ubuntu-novnc || true
      fi

      # Install Chrome inside container
      docker exec -it ubuntu-novnc bash -c "sudo apt update && sudo apt remove -y firefox && sudo apt install -y wget && sudo wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && sudo apt install -y ./google-chrome-stable_current_amd64.deb"

      # Optional: start Cloudflared tunnel in background
      cloudflared tunnel --url http://localhost:8080 &
    '';
  };

  idx.previews = {
    enable = true;
    previews = {
      novnc = {
        manager = "web";   # match Flutter's usage
        command = [
          "bash" "-lc"
          # Must listen on $PORT so IDX knows to show the preview
          "socat TCP-LISTEN:$PORT,fork,reuseaddr TCP:127.0.0.1:8080"
        ];
      };
    };
  };
}
