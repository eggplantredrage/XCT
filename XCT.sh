#!/bin/bash
echo "================================"
echo "XCT XOS Command Tool "
echo "========MENU====================="
echo "Press 1 to update grub"
echo "Press 2 to update Repo's"
echo "Press 3 to repair broken Packages"
echo "Press 4 to see the Linux Version"
echo "Press 5 to Exit"
echo "================================"
echo -e "\n"
echo -e "\n"
echo -e "Enter Your Option \c "
read answer
case "$answer" in 
1) sudo update-grub ;;
2) sudo apt-get -y update ;;
3) sudo apt --fix-missing update
   sudo apt-get clean ;;
4) uname -r ;;
5) exit ;;
esac

