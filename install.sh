#~/bin/bash

mkdir -p ~/.local/bin
cp localhistory.sh ~/.local/bin/localhistory.sh
chmod +x ~/.local/bin/localhistory.sh
# Do not inject into .bashrc twice; checked by if variables set by the script are set
if [ -z "$__LOCALHISTORY_FILENAME" ]; then
    echo "Updating .bashrc"
    echo -e "\n~/.local/bin/localhistory.sh --prompt-command" >> ~/.bashrc
fi
. localhistory.sh

echo "Installed local history script"
echo "Run \"lht help\" for help"