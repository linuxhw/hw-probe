#!/bin/bash
# Written and used by Mikhail Novosyolov <mikhailnov@dumalogiya.ru> for building the hw-probe package to the Launchpad.net PPA repository for Ubuntu and Debian
# Open-sourced to allow other people do the same easily
# Thanks to Denis Linvinus <linvinus@gmail.com> for the base of this script

pkg_name="hw-probe"

# override different ls aliases that may break this script
alias ls="$(which ls)"

# this allows the script to be ran both from the root of the source tree and from ./debian directory
dir_start="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [ "$(basename "${dir_start}")" = 'debian' ]; then
	cd ..
fi
dir0="$(pwd)"
old_header=$(head -1 ./debian/changelog)

for i in trusty xenial artful bionic
do
	old_version="$(cat ./debian/changelog | head -n 1 | awk -F "(" '{print $2}' | awk -F ")" '{print $1}')"
	new_version="${old_version}~${i}1"
	sed -i -re "s/${old_version}/${new_version}/g" ./debian/changelog
	sed -i -re "1s/unstable/$i/" ./debian/changelog
	# -I to exclude .git; -d to allow building .changes file without build dependencies installed
	dpkg-buildpackage -I -S -sa -d
	sed  -i -re "1s/.*/${old_header}/" ./debian/changelog
	cd ..
	
	# change PPA names to yours, you may leave only one PPA; I upload hw-probe to 2 different PPAs at the same time
	for reponame in "ppa:mikhailnov/hw-probe" "ppa:mikhailnov/utils"
	do
		dput -f "$reponame" "$(ls -tr ${pkg_name}_*_source.changes | tail -n 1)" 
	done
	
	cd "$dir0"
	sleep 1
done

cd "$dir_start"
