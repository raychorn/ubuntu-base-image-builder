#!/usr/bin/env bash

PY=$(which python3.9)

if [[ ! -f "$PY" ]]; then
	echo "Python 3.9 is unavailable.  Please fix."
	exit 1
fi

ZSHRC=$HOME/.zshrc

if [[ ! -f "$ZSHRC" ]]; then
	echo "ZSHRC is unavailable.  Please fix."
	exit 1
fi

TEMP_PY_FILE=/tmp/py_util.py
cat << TEMP_PY_FILE_EOF > $TEMP_PY_FILE
import sys
import os

print('DEBUG: {} --> {}'.format(sys.argv[1], sys.argv[2]))
assert os.path.exists(sys.argv[1]), '{} does not exist'.format(sys.argv[1])

print('DEBUG: {} --> {}'.format(sys.argv[3], sys.argv[4]))

assert (sys.argv[3]) and (len(sys.argv[3]) > 0), '{} is empty'.format('sys.argv[3]')
assert (sys.argv[4]) and (len(sys.argv[4]) > 0), '{} is empty'.format('sys.argv[4]')

__is__ = False
__might__ = False
with open(sys.argv[1], "r") as fIn:
    with open(sys.argv[2], "w") as fOut:
        for line in fIn:
            __might__ = (line.find(sys.argv[3]) > -1)
            fOut.write(line.replace(sys.argv[3], sys.argv[4]))
            if (__might__):
                __is__ = True

print('DEBUG (2): {} --> {}'.format(__might__, __is__))
if (__is__):
    os.rename(sys.argv[1], sys.argv[1] + '.bak')
    os.rename(sys.argv[2], sys.argv[1])

TEMP_PY_FILE_EOF

if [[ ! -f "$TEMP_PY_FILE" ]]; then
    echo "TEMP_PY_FILE is unavailable.  Please fix."
    exit 1
fi

$PY $TEMP_PY_FILE $ZSHRC $ZSHRC.new "ZSH_THEME=\"robbyrussell\"" "ZSH_THEME=\"powerlevel10k/powerlevel10k\""

if [[ ! -f "$ZSHRC.new" ]]; then
    #. $ZSHRC
    echo "$ZSHRC has been updated."
else
    echo "$ZSHRC has not been updated."
fi
