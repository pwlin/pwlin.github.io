# commented out !/bin/bash

# wget http://pwlin.github.io/pub/debian/post-install.sh -O post-install.sh && bash post-install.sh && rm post-install.sh

rm -r /var/lib/apt/lists/* 
rm /etc/apt/apt.conf.d/00InstallRecommends 
echo -e 'APT::Install-Recommends "false";\nAPT::Install-Suggests "false";\nAcquire::PDiffs "false";\n' > /etc/apt/apt.conf.d/00InstallRecommends
aptitude update
aptitude -y purge task-english ispell wamerican ienglish-common iamerican ibritish dictionaries-common util-linux-locales info install-info man-db manpages manpages-dev vim-tiny vim-common netcat-traditional traceroute
aptitude -y install openssh-server build-essential ca-certificates sudo xorg xfce4 xdg-utils desktop-base dmz-cursor-theme xfce4-cpugraph-plugin xfce4-terminal thunar-archive-plugin tar bzip2 zip unzip unrar-free ristretto scite xarchiver fonts-droid curl gtk2-engines-murrine htop mc localepurge subversion git php5-cli php5-curl cifs-utils locate gnome-icon-theme

dpkg-reconfigure localepurge
localepurge

# apt-get -y install openjdk-6-jre
# apt-get -y install default-jre-headless
apt-get -y install default-jre

# http://www.uvena.de/gigolo/help.html#open-resources-in-thunar-on-xfce-4-4-and-4-6
#apt-get -y install --no-install-recommends gvfs gvfs-backends gvfs-fuse gfvs-bin gigolo
#gpasswd -a user1 fuse
#sudo -u user1 mkdir -p /home/user1/.local/share/applications
#sudo -u user1 echo -e 'x-scheme-handler/smb=exo-file-manager.desktop\nx-scheme-handler/network=exo-file-manager.desktop\n' > /home/user1/.local/share/applications/mimeapps.list

apt-get -y autoremove
aptitude forget-new 
aptitude clean
aptitude autoclean

# http://wiki.xfce.org/howto/install_new_themes
# http://wiki.xfce.org/howto/customize-menu
rm -rf /root/Downloads/post-install 
mkdir -p /root/Downloads/post-install 
cd /root/Downloads/post-install 

# https://github.com/shimmerproject/Greybird
curl https://nodeload.github.com/shimmerproject/Greybird/zip/master > Greybird.zip
unzip Greybird.zip -d Greybird > /dev/null
rm -rf /usr/share/themes/Greybird 
mkdir -p /usr/share/themes/Greybird 
cp -r Greybird/Greybird-master/* /usr/share/themes/Greybird/ > /dev/null

# https://code.google.com/p/faenza-icon-theme/
# http://ppa.launchpad.net/tiheum/equinox/ubuntu/pool/main/f/faenza-icon-theme/faenza-icon-theme_1.3.1.tar.gz
# https://faenza-icon-theme.googlecode.com/files/faenza-icon-theme_1.3.zip
curl http://pwlin.github.io/pub/debian/files/themes/faenza-icon-theme_1.3.zip > faenza.zip
unzip faenza.zip -d faenza > /dev/null
bash ./faenza/INSTALL

# https://github.com/shimmerproject/Faenza-Xfce
#wget https://nodeload.github.com/shimmerproject/Faenza-Xfce/zip/master -O faenza-xfce.zip
#unzip faenza-xfce.zip faenza-xfce
#mkdir -p /usr/share/icons/Faenza-Xfce
#cp -r faenza-xfce/Faenza-Xfce-master/* /usr/share/icons/Faenza-Xfce/

# http://gnome-look.org/content/show.php/Faenza-Cupertino?content=129008
# http://gnome-look.org/CONTENT/content-files/129008-Faenza-Cupertino.tar.gz
curl http://pwlin.github.io/pub/debian/files/themes/129008-Faenza-Cupertino.tar.gz > faenza-cupertino.tar.gz
tar xvzf faenza-cupertino.tar.gz > /dev/null
rm -rf /usr/share/icons/Faenza-Cupertino 
mkdir -p /usr/share/icons/Faenza-Cupertino 
cp -r Faenza-Cupertino/* /usr/share/icons/Faenza-Cupertino/ > /dev/null

dpkg-reconfigure localepurge
localepurge

cd /root/
rm -rf /root/Downloads/post-install 

# http://askubuntu.com/questions/74345/how-do-i-bypass-ignore-the-gpg-signature-checks-of-apt
# echo -e 'APT::Get::AllowUnauthenticated\n' >> /etc/apt/apt.conf.d/00InstallRecommends

# https://wiki.ubuntu.com/MountWindowsSharesPermanently
# mkdir -p /mnt/usb1 
# echo -e '//192.168.0.20/usb1  /mnt/usb1  cifs  guest,uid=1000  0  0\n' >> /etc/fstab

aptitude -y install libxss1 libnss3 libgconf-2-4
su -s /bin/bash user1 -c 'curl https://raw.github.com/pwlin/chromium-dev-updater/master/src/chromium-dev-updater.php | php'

# http://eclipse.mirror.triple-it.nl/eclipse/downloads/drops/R-3.7.2-201202080800/eclipse-SDK-3.7.2-linux-gtk.tar.gz

su -s /bin/bash user1 -c 'curl http://pwlin.github.io/pub/debian/files/backup/backup-home.tar.gz;tar xzf backup-home.tar.gz;cp -rf /home/user1/backup-home/* /home/user1;rm -rf /home/user1/backup-home;rm backup-home.tar.gz'

mv /root/.bashrc.org /root/.bashrc 


