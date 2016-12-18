#!/bin/bash

# cd /root/ && curl http://192.168.1.4/post-install.sh > post-install.sh && chmod +x post-install.sh && ./post-install.sh

function apt-init() {
	rm -r /var/lib/apt/lists/* 
	echo 'APT::Install-Recommends "false";APT::Install-Suggests "false";Acquire::PDiffs "false";' > /etc/apt/apt.conf.d/00InstallRecommends
	aptitude update
	#ap-get -y upgrade
	#apt-get -y dist-upgrade
}

function apt-init-remove() {
	aptitude -y purge task-english ispell wamerican ienglish-common iamerican ibritish dictionaries-common util-linux-locales vim-tiny vim-common xxd manpages manpages-dev tcpd
}

function install-localepurge() {
	aptitude -y install localepurge
	#dpkg-reconfigure localepurge
	#localepurge
}

function apt-init-install() {
	# xfce4-terminal
	aptitude -y install xfce4 faenza-icon-theme greybird-gtk-theme xdg-utils desktop-base dmz-cursor-theme xfce4-cpugraph-plugin lxterminal thunar-archive-plugin gtk2-engines-murrine gnome-icon-theme ristretto leafpad geany xarchiver
}

function apt-init-install-gvfs() {
	echo ''
	# http://www.uvena.de/gigolo/help.html#open-resources-in-thunar-on-xfce-4-4-and-4-6
	#aptitude -y install gvfs gvfs-backends gvfs-fuse gfvs-bin gigolo
	#gpasswd -a user1 fuse
	#sudo -u user1 mkdir -p /home/user1/.local/share/applications
	#sudo -u user1 echo -e 'x-scheme-handler/smb=exo-file-manager.desktop\nx-scheme-handler/network=exo-file-manager.desktop\n' > /home/user1/.local/share/applications/mimeapps.list
}

function install-themes-init() {
	# http://wiki.xfce.org/howto/install_new_themes
	# http://wiki.xfce.org/howto/customize-menu
	rm -rf /root/Downloads/post-install > /dev/null
	mkdir -p /root/Downloads/post-install 
	cd /root/Downloads/post-install
}

function install-themes-greybird() {
	# https://github.com/shimmerproject/Greybird
	#curl https://nodeload.github.com/shimmerproject/Greybird/zip/master > Greybird.zip
	curl http://192.168.1.4/files/themes/Greybird.zip > Greybird.zip
	unzip Greybird.zip -d Greybird > /dev/null
	rm -rf /usr/share/themes/Greybird > /dev/null
	mkdir -p /usr/share/themes/Greybird 
	cp -r Greybird/Greybird-master/* /usr/share/themes/Greybird/ > /dev/null
}

install-theme-faenza() {
	# https://code.google.com/p/faenza-icon-theme/
	# http://ppa.launchpad.net/tiheum/equinox/ubuntu/pool/main/f/faenza-icon-theme/faenza-icon-theme_1.3.1.tar.gz
	# https://faenza-icon-theme.googlecode.com/files/faenza-icon-theme_1.3.zip
	curl http://192.168.1.4/files/themes/faenza-icon-theme_1.3.zip > faenza.zip
	unzip faenza.zip -d faenza > /dev/null
	bash ./faenza/INSTALL

	gtk-update-icon-cache /usr/share/icons/Faenza/
	gtk-update-icon-cache /usr/share/icons/Faenza-Ambiance/
	gtk-update-icon-cache /usr/share/icons/Faenza-Dark/
	gtk-update-icon-cache /usr/share/icons/Faenza-Darker/
	gtk-update-icon-cache /usr/share/icons/Faenza-Darkest/
	gtk-update-icon-cache /usr/share/icons/Faenza-Radiance/

	#https://github.com/shimmerproject/Faenza-Xfce
	#wget https://nodeload.github.com/shimmerproject/Faenza-Xfce/zip/master -O faenza-xfce.zip
	#unzip faenza-xfce.zip faenza-xfce
	#mkdir -p /usr/share/icons/Faenza-Xfce
	#cp -r faenza-xfce/Faenza-Xfce-master/* /usr/share/icons/Faenza-Xfce/
}

function install-themes-faenza-cupertino() {
	# http://gnome-look.org/content/show.php/Faenza-Cupertino?content=129008
	# http://gnome-look.org/CONTENT/content-files/129008-Faenza-Cupertino.tar.gz
	curl http://192.168.1.4/files/themes/129008-Faenza-Cupertino.tar.gz > faenza-cupertino.tar.gz
	tar xvzf faenza-cupertino.tar.gz > /dev/null
	rm -rf /usr/share/icons/Faenza-Cupertino > /dev/null
	mkdir -p /usr/share/icons/Faenza-Cupertino 
	cp -r Faenza-Cupertino/* /usr/share/icons/Faenza-Cupertino/ > /dev/null
	gtk-update-icon-cache /usr/share/icons/Faenza-Cupertino/
}

function install-themes-post-jobs() {
	cd /root/
	rm -rf /root/Downloads/post-install
}

function apt-set-allow-unauthenticated() {
	echo ''
	# http://askubuntu.com/questions/74345/how-do-i-bypass-ignore-the-gpg-signature-checks-of-apt
	# echo 'APT::Get::AllowUnauthenticated' >> /etc/apt/apt.conf.d/01AllowUnauthenticated
}

function samba-permanent-mounts() {
	echo ''
	# https://wiki.ubuntu.com/MountWindowsSharesPermanently
	# mkdir -p /mnt/usb1 
	# echo -e '//192.168.0.20/usb1  /mnt/usb1  cifs  guest,uid=1000  0  0\n' >> /etc/fstab
	# mount -t cifs -o username=<share user>,password=<share password> //WIN_PC_IP/<share name> /mnt
}

function install-chromium() {
	echo ''
	#aptitude -y install libxss1 libnss3 libgconf-2-4
	#su -s /bin/bash user1 -c 'cd /home/user1/;curl https://raw.githubusercontent.com/pwlin/cr-updater/master/updater.php | php'
}

function install-eclipse() {
	echo ''
	# http://eclipse.mirror.triple-it.nl/eclipse/downloads/drops/R-3.7.2-201202080800/eclipse-SDK-3.7.2-linux-gtk.tar.gz
}

function restore-home() {
	echo ''
	# su -s /bin/bash user1 -c 'cd /tmp;curl http://192.168.1.4/files/backup/backup-home.tar.gz > /tmp/backup-home.tar.gz;tar xzf /tmp/backup-home.tar.gz;cp -a /tmp/home/user1/backup-home /home/user1/;rm -rf /tmp/home;rm /tmp/backup-home.tar.gz'
}

function setup-vnc() {
	#http://stackoverflow.com/questions/30606655/set-up-tightvnc-programmatically-with-bash
	#http://www.penguintutor.com/linux/tightvnc
	curl http://192.168.1.4/tightvncserver.service > /etc/systemd/system/tightvncserver.service
	chown root:root /etc/systemd/system/tightvncserver.service
	chmod 755 /etc/systemd/system/tightvncserver.service
	systemctl enable tightvncserver.service
	su -s /bin/bash user1 -c 'umask 0077;mkdir -p "$HOME/.vnc";chmod go-rwx "$HOME/.vnc";vncpasswd -f <<<"12345678" >"$HOME/.vnc/passwd"'
	su -s /bin/bash user1 -c 'curl http://192.168.1.4/vnc-xstartup > /home/user1/.vnc/xstartup;chmod +x /home/user1/.vnc/xstartup'
	systemctl restart tightvncserver.service
}

function apt-post-jobs() {
	apt-get -y autoremove
	aptitude forget-new 
	aptitude clean
	aptitude autoclean
}

function localepurge-post-jobs() {
	dpkg-reconfigure localepurge
	localepurge
}

function fix-keyboard-auto-completion() {
	su -s /bin/bash user1 -c 'curl http://192.168.1.4/fix-keyboard-auto-completion > /home/user1/fix-keyboard-auto-completion.php;php /home/user1/fix-keyboard-auto-completion.php;rm /home/user1/fix-keyboard-auto-completion.php'
}

apt-init
apt-init-remove
install-localepurge
apt-init-install
install-themes-init
install-themes-faenza-cupertino
install-themes-post-jobs
setup-vnc
apt-post-jobs
localepurge-post-jobs
fix-keyboard-auto-completion


cd /root/
#mv /root/.bashrc.org /root/.bashrc 
rm /root/post-install.sh

reboot
