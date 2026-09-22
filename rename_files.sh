#!/bin/bash
pushd $HOME/tools/os161/bin
for i in mips-*; do
	ln -s $i "os161-$(echo $i | cut -d- -f4)"
done
popd
