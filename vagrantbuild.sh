#!/bin/bash
set -e

if ! [ "`which vagrant`" ]; then
  echo "Please install vagrant"
  exit 1
fi

if ! [ "`vagrant status | grep running |head -1`" ]; then
 ./vagrantfiles/provision.sh
fi

./clean.sh

if [ "$1" = "clean" ]; then
  echo "Cleaning Files"
  vagrant ssh -c "rm -Rf \$HOME/ride"
fi
  echo "Copying Files"
vagrant ssh -c "cp -Ruv /ride \$HOME/"
  echo "Building"
vagrant ssh -c "cd \$HOME/ride && npm i && . dist.sh"
vagrant ssh -c "cp -Ruv \$HOME/ride/build /ride/"

case `uname` in
    Linux)
          case `uname -m` in
            x86_64)
                RIDEBIN=linux64/ride30
                ;;
              x86)
                RIDEBIN=linux32/ride30
                ;;
          esac
          ;;
    Darwin)
          RIDEBIN=osx64/ride30.app/Contents/MacOS/node-webkit
          ;;
    MINGW*)
          RIDEBIN=win32/ride30.exe
          ;;
esac

echo "Running RIDE for `uname`"
./build/ride/${RIDEBIN}
