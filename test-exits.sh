#!/bin/bash
set -Eeuo pipefail

SCRIPTNAME=${0#*/} ; die() { [ -z "$*" ] || echo "$SCRIPTNAME: $*" >&2; exit 9 ; }

# create AppImage with controllable exit statis
mkdir -p AppDir/

cat > AppDir/AppRun <<\__EOF
#!/bin/sh

test "$1" = "-e" && exit $2

test "$1" = "-k" && kill -$2 $$

echo "Usage: $0 [-e <exitstatus>] [-k <signal>]"
__EOF
chmod +x AppDir/AppRun

mksquashfs AppDir/ tmp.sqfs -root-owned -noappend -no-exports >/dev/null
cat ./build/src/runtime tmp.sqfs > test-exits.AppImage && rm -f tmp.sqfs

( set -x ; chmod +x test-exits.AppImage )

# check various exit modes
set +e
for OPT in "" --appimage-extract-and-run ; do
  for e in 0 1 2 3 4 5 6 7 8 9 ; do
    POSTFIX="${OPT:+, options: $OPT}"
    echo "  TEST    AppImage exit statues$POSTFIX: $e"
    ./test-exits.AppImage $OPT -e $e ; test "$?" = $e || die "failed exit status: $e"
    echo "  OK      AppImage exit statues $e"
  done
done

# test some signals
echo "  TEST    AppImage signal exit: 9"
./test-exits.AppImage -k 9 && die "failed signal exit status: 9"
echo "  TEST    AppImage signal exit, options: --appimage-extract-and-run: 9"
./test-exits.AppImage --appimage-extract-and-run -k 9 && die "failed signal exit status: 9"

# done
rm -f test-exits.AppImage
