#!/bin/bash

# Usage: ./java.sh [--print] [path]
# --print: only print the command, don't execute it
# path: path to the application. If blank, assume the current directory
#       e.g. "/Applications/Minecraft.app/"
#       e.g. "/Applications/Runescape.app/"

# Uncomment and edit the line below if you want to run this without arguments
# e.g. "cd /Applications/Minecraft.app/"
# e.g. "cd /Applications/Runescape.app/"
# cd /path/to/MyApplication.app/

PRINT=false
if [[ "$1" == "--print" ]]; then
	PRINT=true
	shift
fi

CMD=$(python - $1 << 'EOF'
import sys
import os
import subprocess
import plistlib

def shell_escape(s):
	return s.replace("'", "'\"'\"'")

app_path = '.'
if len(sys.argv) > 1:
	app_path = sys.argv[1]

with open(os.path.join(app_path, 'Contents/Info.plist'), 'rb') as f:
	p = None
	try:
		p = plistlib.load(f)
	except AttributeError:
		p = plistlib.readPlist(f)

	java_properties = []
	for k in p['Java']['Properties']:
		java_properties.append("'-D{0}={1}'".format(k, p['Java']['Properties'][k]))

	java_cmd = ['java']
	vm_opts = p['Java'].get('VMOptions')
	if vm_opts is None:
		vm_opts = p['Java'].get('VMOptions.x86_64')
	if not vm_opts is None:
		java_cmd.append(vm_opts)
	java_cmd.extend(java_properties)
	java_cmd.extend(['-cp', p['Java']['ClassPath'], p['Java']['MainClass']])
	java_args = p['Java'].get('Arguments')
	if not java_args is None:
		java_cmd.append(java_args)

	env = {
		'APP_PACKAGE': os.path.abspath(app_path),
		'JAVAROOT': os.path.abspath(os.path.join(app_path, 'Contents/Resources/Java')),
	}

	cmd = []
	for k in env:
		cmd.append('{0}={1}'.format(k, env[k]))
	cmd.append("bash -c '{0}'".format(shell_escape(' '.join(java_cmd))))

	print(' '.join(cmd))
EOF
)

echo "$CMD"
if [[ "$PRINT" == false ]]; then
	bash -c "$CMD"
fi
