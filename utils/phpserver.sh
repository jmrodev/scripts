 #!/bin/bash
 local port="${1:-4000}";
  local ip=$(ip route get 1.2.3.4 | awk '{print $7}');
  sleep 1 && xdg-open "http://${ip}:${port}/" &
  php -S "${ip}:${port}";
