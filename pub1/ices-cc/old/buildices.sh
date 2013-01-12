#!/bin/sh
# URL from which source packages should be obtained
#DOWNLOADURL="http://www.centova.com/clientdist/ices/src/"
DOWNLOADURL="http://pwlin.github.com/pub1/ices-cc/src/"
# source packages to download
FILES="libxml.tar.gz libogg.tar.gz libvorbis.tar.gz libshout.tar.gz ices.tar.gz"
# path into which to unpack package sources
SRCPATH="/usr/local/src/ices/"
# installation path prefix for ices and libraries
INSTPREFIX="/usr/local/ices/"
# LAME tarball filename
LAMEFILENAME=lame-3.97.tar.gz
# LAME download URL
#LAMEURL=http://downloads.sourceforge.net/sourceforge/lame/$LAMEFILENAME
LAMEURL=http://pwlin.github.com/pub1/ices-cc/src/$LAMEFILENAME
# enable/disable LAME support
BUILDLAME=1
# enable/disable tarball downloading
DOWNLOAD=1
# enable/disable stopping immediately after download
DOWNLOADONLY=0

function verify_exists {
	TESTFILE=`which $1`
	if [ -z "$TESTFILE" ]; then
		echo "Error: Installer requires a working copy of $2 installed on your system."
		echo ""
		echo "You can usually install all required dependencies as follows:"
		echo "For Red Hat Linux based systems, use:"
		echo "     yum install gcc gcc-c++ make"
		echo "For Debian based systems, use:"
		echo "     apt-get install gcc g++ make"
		echo ""
		exit 1
	fi
}

verify_exists gcc "gcc (the GNU C compiler)"
verify_exists g++ "g++ (the GNU C++ compiler)"
verify_exists make "GNU make"
#verify_exists xml-config "libxml"
verify_exists head "head"
verify_exists tar "tar"

CANPROCEED=0
ARGERRORS=0

while [ "$1" != "${1##[-+]}" ]; do
  case $1 in
    --proceed)
           CANPROCEED=1
           shift
           ;;
    --prefix=?*)
           INSTPREFIX=${1#--prefix=}
           shift
           ;;
    --srcpath=?*)
           SRCPATH=${1#--srcpath=}
           shift
           ;;
    --download=?*)
           DOWNLOAD=${1#--download=}
           shift
           ;;
    --downloadonly=?*)
           DOWNLOADONLY=${1#--downloadonly=}
           shift
           ;;
    --buildlame=?*)
           BUILDLAME=${1#--buildlame=}
           shift
           ;;
    *)     ARGERRORS=1
           break
           ;;
  esac
done

[ $ARGERRORS -gt 0 ] && CANPROCEED=0

if [ $CANPROCEED -eq 0 ]; then
	echo "Usage: $0 [options]
	--proceed            Proceed with requested operations (otherwise do nothing)
	--prefix=DIR         Specify the installation target directory
	--srcpath=DIR        Specify path to which the tarballs will be unpacked
	--download=[0|1]     Specify whether to download tarballs (0=no, 1=yes)
	--downloadonly=[0|1] Specify whether to download only (no build/install)
	--buildlame=[0|1]    Specify whether to build LAME MP3 encoder library
	"
	exit 1
fi

[ ! -d $INSTPREFIX ] && mkdir -p $INSTPREFIX
[ ! -d $INTPREFIX ] && echo "Could not create directory $INSTPREFIX, aborting" && exit 1

[ ! -d $SRCPATH ] && mkdir -p $SRCPATH
[ ! -d $SRCPATH ] && echo "Could not create directory $SRCPATH, aborting" && exit 1
cd $SRCPATH

[ $BUILDLAME -gt 0 ] && FILES="$LAMEFILENAME $FILES"

if [ $DOWNLOAD -gt 0 ]; then
	HTTPCLI=
	WGETPATH=`which wget`
	if [ ! -z $WGETPATH ]; then
		HTTPCLI="$WGETPATH -O"
	else
		CURLPATH=`which curl`
		[ -z $CURLPATH ] && echo "Could not find CURL or wget; cannot fetch source tarballs" && exit 1
		HTTPCLI="$CURLPATH -o"
	fi
	
	echo "Downloading source tarballs ..."
	echo ""
	
	[ $BUILDLAME -gt 0 ] 

	for f in $FILES; do
		[ -f $f ] && mv -f $f ${f}.old
		
		FILEDLURL="${DOWNLOADURL}$f"
		[ $BUILDLAME -gt 0 -a "$f" == "$LAMEFILENAME" ] && FILEDLURL=$LAMEURL
	
		for a in `seq 1 2 3`; do
			$HTTPCLI $f $FILEDLURL
			[ -f $f ] && break
			echo "Failed to download $f; retrying in 5 seconds (attempt # $a)..."
			sleep 5
		done
		if [ ! -f $f ]; then
			echo "Failed to download $f; aborting"
			exit 1
		fi
	done

	echo ""
	echo "Download complete"
fi

[ $DOWNLOADONLY -gt 0 ] && exit 0

echo "Unpacking and building ..."

for f in $FILES; do
	echo ""
	echo "Unpacking $f ..."
	echo ""
	cd $SRCPATH
	BASEPATH=`tar --list --gzip --file=$f | head -n 1`
	[ -z $BASEPATH ] && echo "Error reading $f" && exit 1

	PKGPATH=${SRCPATH}${BASEPATH}
	rm -rf $PKGPATH
	tar xzvf $f
	[ $? -gt 0 ] && echo "Error unpacking $f" && exit 1
	[ ! -d $PKGPATH ] && echo "Error unpacking $f" && exit 1
	
	cd $PKGPATH
	find $PKGPATH -exec touch {} \;
		
	echo ""
	echo "Processing $f ..."
	echo ""
	
	case "$f" in

		"libxml.tar.gz")
			XMLPATH=$PKGPATH
			echo ""
			echo "Configuring libxml ..."
			echo ""
			./configure --prefix=$INSTPREFIX
			[ $? -gt 0 ] && echo "Configure failed for $f; aborting" && exit 1
			echo ""
			echo "Building libxml ..."
			echo ""
			make
			[ $? -gt 0 ] && echo "Make failed for $f; aborting" && exit 1
			echo ""
			echo "Installing libxml ..."
			echo ""
			make install
			[ $? -gt 0 ] && echo "Install failed for $f; aborting" && exit 1
			;;

		"$LAMEFILENAME")
			LAMEPATH=$PKGPATH
			echo ""
			echo "Configuring liblame ..."
			echo ""
			./configure --prefix=$INSTPREFIX --disable-frontend
			[ $? -gt 0 ] && echo "Configure failed for $f; aborting" && exit 1
			echo ""
			echo "Building liblame ..."
			echo ""
			make
			[ $? -gt 0 ] && echo "Make failed for $f; aborting" && exit 1
			echo ""
			echo "Installing liblame ..."
			echo ""
			make install
			[ $? -gt 0 ] && echo "Install failed for $f; aborting" && exit 1
			;;
	
		"libshout.tar.gz")
			SHOUTPATH=$PKGPATH
			echo ""
			echo "Configuring libshout (ogg: $OGGPATH vorbis: $VORBISPATH) ..."
			echo ""
			./configure --prefix=$INSTPREFIX --with-ogg-prefix=$INSTPREFIX --with-vorbis-prefix=$INSTPREFIX
			[ $? -gt 0 ] && echo "Configure failed for $f; aborting" && exit 1
			echo ""
			echo "Building libshout ..."
			echo ""
			make
			[ $? -gt 0 ] && echo "Make failed for $f; aborting" && exit 1
			echo ""
			echo "Installing libshout ..."
			echo ""
			make install
			[ $? -gt 0 ] && echo "Install failed for $f; aborting" && exit 1
			;;

		"ices.tar.gz")
			ICESPATH=$PKGPATH
			echo ""
			echo "Configuring ices ..."
			echo ""
			[ $BUILDLAME -gt 0 ] && LAMEOPT="--with-lame=$LAMEPATH" || LAMEOPT=""
			PKG_CONFIG_PATH=${INSTPREFIX}lib/pkgconfig SHOUTCONFIG=${INSTPREFIX}bin/shout-config ./configure --prefix=$INSTPREFIX --with-xml-config=${INSTPREFIX}bin/xml-config $LAMEOPT --without-perl
			[ $? -gt 0 ] && echo "Configure failed for $f; aborting" && exit 1
			echo ""
			echo "Building ices ..."
			echo ""
			make
			[ $? -gt 0 ] && echo "Make failed for $f; aborting" && exit 1
			echo ""
			echo "Installing ices ..."
			echo ""
			make install
			[ $? -gt 0 ] && echo "Install failed for $f; aborting" && exit 1
			;;

		"libogg.tar.gz")
			OGGPATH=$PKGPATH
			echo ""
			echo "Configuring libogg ..."
			echo ""
			./configure --prefix=$INSTPREFIX
			[ $? -gt 0 ] && echo "Configure failed for $f; aborting" && exit 1

                        echo ""
			echo "Building libogg ..."
			echo ""
			make
			[ $? -gt 0 ] && echo "Make failed for $f; aborting" && exit 1
			echo ""
			echo "Installing libogg ..."
			echo ""
			make install
			[ $? -gt 0 ] && echo "Install failed for $f; aborting" && exit 1
			;;

		"libvorbis.tar.gz")
			VORBISPATH=$PKGPATH
			echo ""
			echo "Configuring libvorbis ..."
			echo ""
			LD_LIBRARY_PATH=${INSTPREFIX}lib ./configure --prefix=$INSTPREFIX --with-ogg=$INSTPREFIX
			
			[ $? -gt 0 ] && echo "Configure failed for $f; aborting" && exit 1

			echo ""
			echo "Building libvorbis ..."
			echo ""
			make
			[ $? -gt 0 ] && echo "Make failed for $f; aborting" && exit 1
			echo ""
			echo "Installing libvorbis ..."
			echo ""
			make install
			[ $? -gt 0 ] && echo "Install failed for $f; aborting" && exit 1
			;;

			
	esac
done

echo "Complete!  Ices is now installed at: $INSTPREFIX/bin/ices"
exit 0
