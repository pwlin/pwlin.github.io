HISTIGNORE='x'
alias sudo='sudo '
shopt -s globstar
PROMPT_COMMAND="history -a;$PROMPT_COMMAND"
complete -cf sudo
#export PATH="$PATH:/home/myuser/bin1"

alias ll='ls -lAhF --group-directories-first'
alias l='ls -AhF --group-directories-first'
alias dirb='find `pwd` -maxdepth 1'
alias d='date'
alias cls='clear && date'
alias t='top'
alias h='htop'
alias hds='df -h'
alias ds='du --exclude=".svn" -c -h --time'
alias mc='mc -s'
alias smc='sudo mc '
alias mut='alpine'
alias x='exit'
alias git-revert="git fetch origin && git reset --hard origin/master"
alias apti='sudo aptitude'
alias re-apt='sudo aptitude install -o Dpkg::Options::=--force-confmiss '
alias aptall='sudo rm -rf /var/lib/apt/lists && sudo apt-get update && sudo apt-get -y upgrade && sudo apt-get -y dist-upgrade && sudo apt-get -y autoremove && sudo apt-get autoclean && sudo apt clean'
alias cports='sudo lsof -i && sudo netstat -lptu'
alias service-list='sudo systemctl list-unit-files'
alias curl='curl --compressed '
alias locate-update='sudo updatedb '
alias untar='tar -xzvf '

function find-all() {
    sudo find $1 -name "$2" -print
}
function find-file() {
    sudo find $1 -type f -name "$2" -print
}
function find-dir() {
    sudo find $1 -type d -name "$2" -print
}

function list-files() {
    find "$1" -maxdepth 1 -type f -exec basename {} \; | sort
}

function list-dirs() {
    find "$1" -maxdepth 1 -type d -exec basename {} \; | sort
}

function list-all() {
    list-dirs "$1"
    list-files "$1"
}

function service-status() {
    sudo systemctl status $1.service
}
function service-enable() {
    sudo systemctl enable $1.service
    sudo service $1 start
    service-status $1
}
function service-disable() {
    sudo service $1 stop
    service-status $1
    sudo systemctl disable $1.service
}
function service-start() {
    sudo service $1 start
    service-status $1
}
function service-stop() {
    sudo service $1 stop
    service-status $1
}
function service-restart() {
    sudo service $1 restart
    service-status $1
}
alias hh='mc -e /home/cyrus/.bash_aliases'
alias calcdir='sudo du -ch | grep total'

alias samba-restart='service-restart smbd && service-restart nmbd '
alias npm-list-main='npm list -q --depth=0 '
function dirsize() {
    sudo du -ch "$1" | grep total
}

function view-logs() {
    sudo journalctl -fu $1
}

function certbot-wildcard() {
    sudo certbot certonly --manual --preferred-challenges=dns --email email@email --server https://acme-v02.api.letsencrypt.org/directory -d *.$1 -d $1
}

alias what-is-my-ip="ip addr show ens3| grep inet | awk '{ print $2; }' | sed 's/\/.*$//'"
function find-file() {
    sudo find . -name $1 -type f
}

#sudo sshfs -o allow_other,default_permissions -p __port__ user@host.com:/ /media/folder1
#alias sshfs-mount="sudo sshfs -o allow_other,default_permissions -p $2 $1:/ $3"
function sshfs-mount() {
    sudo sshfs -o allow_other,default_permissions -p $2 $1:/ $3
}

# https://toolbox.googleapps.com/apps/dig/#TXT/_acme-challenge.myflix.vip
## sudo certbot certonly --manual --preferred-challenges=dns --email email@email --server https://acme-v02.api.letsencrypt.org/directory -d *.mydomain.com -d mydomain.com

alias npm='npm --no-fund --no-audit --no-update-notifier '

function tar-gz-dir() {
    tar -czvf $1.tar.gz $1
}

function untar-gz-file() {
    tar -xzvf $1
}
