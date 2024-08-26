#! /usr/bin/env nix-shell
#! nix-shell -i bash --packages bash pv

set -e

rsync -arPWx --delete /storage/frigate/media/ /f/frigate/media/
