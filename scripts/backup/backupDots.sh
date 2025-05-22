 #!/bin/bash
  pacman -Qqm > ~/pkglist-aur.txt
  pacman -Qqe > ~/pkglist.txt
  dotbare commit -a -m "ultimo backup"
  dotbare push -u origin main
