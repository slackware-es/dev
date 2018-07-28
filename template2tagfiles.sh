#!/bin/sh
# Script taken from:
# https://slackware.uk/people/alien/tools/template2tagfiles.sh
# $Id: template2tagfiles.sh,v 1.2 2016/06/02 10:14:58 eha Exp eha $

# Default values:
DEF_SLACKREMOTE="bear.alienbase.nl/mirrors/slackware/"
DEF_SLKVER="current"
DEF_SLKARCH="x86_64"

help() {
cat <<"EOT"
$Id: template2tagfiles.sh,v 1.2 2016/06/02 10:14:58 eha Exp eha $
EOT
cat <<EOT
  $(basename $0):
  This script takes a slackpkg template file as input and produces
  a tarball containing Slackware tagfiles.
  Every package mentioned in the template file will be set to "ADD"
  in the appropriate tagfile.
  All other packages in the tagfiles will be set to "SKP"

  Parameters:
  -a <arch>     Specify architecture ('${DEF_SLKARCH}' by default).
  -h            This help text.
  -r <server>   The name of a Slackware rsync mirror server and the root of
                the Slackware release tree
                ('${DEF_SLACKREMOTE}' by default).
  -s <filename> The name of the slackpkg template file.
  -t <filename> The name of the tarball for the tagfile directory tree.
  -z <version>  The version of Slackware ('${DEF_SLKVER}' by default).
EOT
}

# Option parsing:
while getopts "a:hr:s:t:z:" Option
do
  case $Option in
    a ) SLKARCH="${OPTARG}"
        ;;
    h ) help ; exit 0
        ;;
    r ) SLACKREMOTE="${OPTARG}"
        ;;
    s ) SLKTPL="${OPTARG}"
        ;;
    t ) TAGBALL="${OPTARG}"
        ;;
    z ) SLKVER="${OPTARG}"
        ;;
    * ) echo "Unsupported parameter."; exit 1
        ;;   # DEFAULT
  esac
done
shift $(($OPTIND - 1))
# End of option parsing.

if [ -z "$SLKTPL" -o -z "$TAGBALL" ]; then
  help
  exit 1
fi

SLACKREMOTE=${SLACKREMOTE:-"${DEF_SLACKREMOTE}"}
SLKVER=${SLKVER:-"${DEF_SLKVER}"}
SLKARCH=${SLKARCH:-"${DEF_SLKARCH}"}
[ "$SLKARCH" = "x86_64" ] && ARCHSUFF="64" || ARCHSUFF="" 

# Create temporary work directory:
SLKTEMP=$(mktemp -d -t alientag.XXXXXX)
if [ ! -d $SLKTEMP ]; then
  echo "Failed to create temporary directory for tagfile extraction!"
  exit 1
fi

# Get the tagfiles from the Slackware mirror:
rsync -aR --no-motd rsync://${SLACKREMOTE}/slackware${ARCHSUFF}-${SLKVER}/slackware${ARCHSUFF}/*/tagfile ${SLKTEMP}/

# First, set all packages to "SKP" in the tagfiles:
find ${SLKTEMP} -name tagfile -exec sed -i -e "s/\(.*\):.*/\1:SKP/" {} \;

# Change all packages mentioned in the template to "ADD" in the tagfiles:
for SLKPKG in $(cat $SLKTPL); do
  SLKTAG=$(find ${SLKTEMP} -name tagfile |xargs grep "^${SLKPKG}:" |cut -d: -f1)
  # Ignore template package names that are not mentioned in a tagfile:
  [ -z "$SLKTAG" ] && continue
  sed -i -e "s/^${SLKPKG}:.*/${SLKPKG}:ADD/" ${SLKTAG}
done

# Where are directories a,ap,d,...,y located:
TAGROOT=$(dirname $(dirname $(find ${SLKTEMP} -name tagfile |grep /a/tagfile)))
# Two levels up (slackware${ARCHSUFF}-${SLKVER}/slackware${ARCHSUFF}):
cd ${TAGROOT}/../../
  # And pack them up:
  tar -Jcf ${TAGBALL} slackware${ARCHSUFF}-${SLKVER}
  echo "Tagfile tarball created: ${TAGBALL}"
cd - 1>/dev/null

# Cleanup:
rm -rf ${SLKTEMP}
