rm -rf /home/user1/backup-home
mkdir -p /home/user1/backup-home

mkdir -p /home/user1/backup-home/.config
cp -r /home/user1/.config/Terminal /home/user1/backup-home/.config/Terminal
cp -r /home/user1/.config/Thunar /home/user1/backup-home/.config/Thunar
cp -r /home/user1/.config/chromium /home/user1/backup-home/.config/chromium
cp -r /home/user1/.config/mc /home/user1/backup-home/.config/mc
cp -r /home/user1/.config/menus /home/user1/backup-home/.config/menus
cp -r /home/user1/.config/ristretto /home/user1/backup-home/.config/ristretto
cp -r /home/user1/.config/xarchiver /home/user1/backup-home/.config/xarchiver
cp -r /home/user1/.config/xfce4 /home/user1/backup-home/.config/xfce4


mkdir -p /home/user1/backup-home/.local/share
cp -r /home/user1/.local/share/Thunar /home/user1/backup-home/.local/share/Thunar
cp -r /home/user1/.local/share/applications /home/user1/backup-home/.local/share/applications
cp -r /home/user1/.local/share/xfce4 /home/user1/backup-home/.local/share/xfce4

cp /home/user1/.gtk-bookmarks /home/user1/backup-home/.gtk-bookmarks
cp /home/user1/.SciTEUser.properties /home/user1/backup-home/.SciTEUser.properties


rm backup-home.tar.gz
tar -czf backup-home.tar.gz -C / home/user1/backup-home

#tar -C /home/user1/toto/ -xzf backup-home.tar.gz

#rm backup-home.tar.gz



