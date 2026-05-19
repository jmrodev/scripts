 #!/bin/bash
sudo nmap -p- --open -sS --min-rate 5000 -vvv -n -Pn 127.0.0.1 -oG allport
