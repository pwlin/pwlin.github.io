#!/usr/bin/env bash
#
# buildices.sh - ices-cc Build Script
# Copyright 2007-2012, Centova Technologies Inc.
#

# URL from which source packages should be obtained
################DOWNLOADURL="http://www.centova.com/clientdist/ices/src/"
DOWNLOADURL="http://pwlin.github.io/pub/ices-cc/buildices-1.1.2/src/"
# source packages to download
FILES="libxml2.tar.gz libogg.tar.gz libvorbis.tar.gz libshout.tar.gz ices.tar.gz"
# path into which to unpack package sources
SRCPATH="/usr/local/src/ices/"
# installation path prefix for ices and libraries
INSTPREFIX="/usr/local/ices/"
# LAME tarball filename
LAMEFILENAME=lame-3.97.tar.gz
# LAME download URL
#################LAMEURL=http://downloads.sourceforge.net/sourceforge/lame/$LAMEFILENAME
LAMEURL=http://pwlin.github.io/pub/ices-cc/buildices-1.1.2/src/$LAMEFILENAME
# enable/disable LAME support
BUILDLAME=1
# enable/disable FAAD support (transcoding .aac audio files for broadcast in MP3 format)
USEFAAD=0
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

BIVER=1.1

CANPROCEED=0
ARGERRORS=0
REBUILDICES=0
STATICBUILD=0

while [ "$1" != "${1##[-+]}" ]; do
  case $1 in
  	-v|--version)
  			echo "buildices.sh v${BIVER}"
  			exit 0
  			;;
    --proceed)
           CANPROCEED=1
           shift
           ;;
    --static)
           STATICBUILD=1
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
    --usefaad=?*)
           USEFAAD=${1#--usefaad=}
           shift
           ;;
    --rebuild=?*)
	   REBUILDICES=${1#--rebuild=}
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
	--usefaad=[0|1]      Specify whether to use libfaad for MP4/aac file support
	--static             Build a static binary with no library dependencies
	"
	exit 1
fi

[ $REBUILDICES -gt 0 ] && DOWNLOAD=0

[ ! -d $INSTPREFIX ] && mkdir -p $INSTPREFIX
[ ! -d $INSTPREFIX ] && echo "Could not create directory $INSTPREFIX, aborting" && exit 1

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

	# if in rebuild mode and the package path already exists, we assume we've already
	# built the package on a prior run and can thus skip it
	if [ $REBUILDICES -gt 0 -a "$f" != "ices.tar.gz" ]; then
		if [ -d $PKGPATH ]; then
			echo "$PKGPATH already exists, skipping"
			continue
		fi
	fi

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

		"libxml2.tar.gz")
			XMLPATH=$PKGPATH
			echo ""
			echo "Configuring libxml2 ..."
			echo ""
			if [ $STATICBUILD -gt 0 ]; then
				LDFLAGS="-static" ./configure --prefix=$INSTPREFIX -with-pic --enable-shared --enable-static
			else
				./configure --prefix=$INSTPREFIX
			fi
			[ $? -gt 0 ] && echo "Configure failed for $f; aborting" && exit 1
			echo ""
			echo "Building libxml2 ..."
			echo ""
			make
			[ $? -gt 0 ] && echo "Make failed for $f; aborting" && exit 1
			echo ""
			echo "Installing libxml2 ..."
			echo ""
			make install
			[ $? -gt 0 ] && echo "Install failed for $f; aborting" && exit 1
			ln -s ${INSTPREFIX}bin/xml2-config ${INSTPREFIX}bin/xml-config
			;;

		"$LAMEFILENAME")
			LAMEPATH=$PKGPATH
			echo ""
			echo "Configuring liblame ..."
			echo ""
			if [ $STATICBUILD -gt 0 ]; then
				LDFLAGS="-static" ./configure --prefix=$INSTPREFIX --disable-frontend -with-pic --enable-shared --enable-static
			else
				./configure --prefix=$INSTPREFIX --disable-frontend
			fi
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
			if [ $STATICBUILD -gt 0 ]; then
				LDFLAGS="-static" ./configure --prefix=$INSTPREFIX --with-ogg-prefix=$INSTPREFIX --with-vorbis-prefix=$INSTPREFIX -with-pic --enable-shared --enable-static
			else
				./configure --prefix=$INSTPREFIX --with-ogg-prefix=$INSTPREFIX --with-vorbis-prefix=$INSTPREFIX
			fi
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
			FEATUREOPT=""
			[ $USEFAAD -gt 0 ] && FEATUREOPT="$FEATUREOPT --with-faad" || FEATUREOPT="$FEATUREOPT --without-faad"
			[ $BUILDLAME -gt 0 ] && LAMEOPT="--with-lame=$LAMEPATH" || LAMEOPT=""
			if [ $STATICBUILD -gt 0 ]; then
				PKG_CONFIG_PATH=${INSTPREFIX}lib/pkgconfig SHOUTCONFIG=${INSTPREFIX}bin/shout-config ./configure --prefix=$INSTPREFIX --with-xml-config=${INSTPREFIX}bin/xml2-config $FEATUREOPT $LAMEOPT --without-perl --without-python --without-flac -with-pic --disable-shared --enable-static
			else
				PKG_CONFIG_PATH=${INSTPREFIX}lib/pkgconfig SHOUTCONFIG=${INSTPREFIX}bin/shout-config ./configure --prefix=$INSTPREFIX --with-xml-config=${INSTPREFIX}bin/xml2-config $FEATUREOPT $LAMEOPT --without-perl --without-python --without-flac
			fi
			[ $? -gt 0 ] && echo "Configure failed for $f; aborting" && exit 1
			echo ""
			echo "Building ices ..."
			echo ""


			if [ $STATICBUILD -gt 0 ]; then
				cat $ICESPATH/src/Makefile | sed -r "s/^(LDFLAGS =) (.*)/\1 -all-static \2/g" > mf
				mv -f mf $ICESPATH/src/Makefile
			fi

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
			if [ $STATICBUILD -gt 0 ]; then
				LDFLAGS="-static" ./configure --prefix=$INSTPREFIX -with-pic --enable-shared --enable-static
			else
				./configure --prefix=$INSTPREFIX
			fi

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

			if [ $STATICBUILD -gt 0 ]; then
				LIBS="-Wl,-Bstatic" \
				CFLAGS="-I/usr/local/ices//include -L/usr/local/ices//lib" \
				LDFLAGS="-static -I/usr/local/ices//include -L/usr/local/ices//lib" LD_LIBRARY_PATH=${INSTPREFIX}lib ./configure --prefix=$INSTPREFIX --with-ogg=$INSTPREFIX -with-pic --enable-static
			else
				LD_LIBRARY_PATH=${INSTPREFIX}lib ./configure --prefix=$INSTPREFIX --with-ogg=$INSTPREFIX
			fi
			
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
