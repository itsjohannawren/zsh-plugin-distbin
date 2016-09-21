#!/bin/bash

__JWALTER_DISTBIN_PATH="bin/distbin"
__JWALTER_DISTBIN_PATHS=("${HOME}/${__JWALTER_DISTBIN_PATH}")
__JWALTER_DISTBIN_PATH_POSITION="${JWALTER_DISTBIN_PATH_POSITION:-last}"

# =============================================================================

# Get the name of the OS from the kernel
__JWALTER_DISTBIN_OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
# Add it to the path for OS-specific scripts
__JWALTER_DISTBIN_PATHS+=("${HOME}/${__JWALTER_DISTBIN_PATH}/${__JWALTER_DISTBIN_OS}")

# Get the kernel architecture for statically linked binaries
__JWALTER_DISTBIN_ARCH="$(uname -m)"
case "${__JWALTER_DISTBIN_ARCH}" in
	x86_64|amd64)
		__JWALTER_DISTBIN_ARCH="x86_64"
		;;
	x86|x86_32|x32|i386|i486|i586|i686)
		__JWALTER_DISTBIN_ARCH="x86"
		;;
esac
# Add the path
__JWALTER_DISTBIN_PATHS+=("${HOME}/${__JWALTER_DISTBIN_PATH}/${__JWALTER_DISTBIN_OS}/${__JWALTER_DISTBIN_ARCH}")

# Attempt to determine distribution name, release, and library archictures (32/64)
if [ -e /etc/centos-release ]; then
	__JWALTER_DISTBIN_DISTRO="centos"
	__JWALTER_DISTBIN_RELEASE="$(awk '/release/ {sub(/^.*release +/,"",$0);sub(/\..*/,"",$1); printf("%s",$1);}' /etc/centos-release)"

elif [ -e /etc/gentoo-release ]; then
	__JWALTER_DISTBIN_DISTRO="gentoo"
	__JWALTER_DISTBIN_RELEASE="$(awk '/release/ {printf("%s",$NF);}' </etc/gentoo-release)"

elif [ -e /etc/os-release ]; then
	__JWALTER_DISTBIN_DISTRO="$(awk 'BEGIN{FS="=\"";} /^NAME=/ {sub(/"$/,"",$0); printf("%s",tolower($2));}' /etc/os-release)"
	__JWALTER_DISTBIN_RELEASE="$(awk 'BEGIN{FS="=\"";} /^VERSION_ID=/ {sub(/\"$/,""); printf("%s",$2);}' /etc/os-release)"

elif [ -e /etc/system-release ]; then
	__JWALTER_DISTBIN_DISTRO="$(awk '/release/ {printf("%s",tolower($1));}' /etc/system-release)"
	__JWALTER_DISTBIN_RELEASE="$(awk '/release/ {gsub(/\.*/,"",$3); printf("%s",$3);}'</etc/system-release)"

elif [ -e /etc/lsb-release ]; then
	__JWALTER_DISTBIN_DISTRO="$(awk 'BEGIN{FS="=";} /^DISTRIB_ID=/ {printf("%s",tolower($2));}' /etc/lsb-release)"
	__JWALTER_DISTBIN_RELEASE="$(awk 'BEGIN{FS="=";} /^DISTRIB_RELEASE=/ {printf("%s",$2);}' /etc/lsb-release)"

elif which sw_vers &>/dev/null; then
	__JWALTER_DISTBIN_DISTRO="osx"
	__JWALTER_DISTBIN_RELEASE="$(sw_vers -productVersion 2>/dev/null | grep -oE '^\d+(\.\d+)?')"
fi

if [ -n "${__JWALTER_DISTBIN_DISTRO}" ] && [ -n "${__JWALTER_DISTBIN_RELEASE}" ]; then
	__JWALTER_DISTBIN_LIBS=()
	__JWALTER_DISTBIN_LINKERS=()

	#shellcheck disable=2162
	while read __JWALTER_DISTBIN_LINKER; do
		__JWALTER_DISTBIN_LINKERS+=("${__JWALTER_DISTBIN_LINKER}")
	done <<<"$(find /lib /lib32 /lib64 /usr/lib /usr/lib32 /usr/lib64 -maxdepth 1 -mindepth 1 -type f -name 'ld-*.so' 2>/dev/null)"

	for __JWALTER_DISTBIN_LINKER in "${__JWALTER_DISTBIN_LINKERS[@]}"; do
		if [ -n "${__JWALTER_DISTBIN_LINKER}" ]; then
			for __JWALTER_DISTBIN_LIB in $(file -b "${__JWALTER_DISTBIN_LINKER}" | awk '/^ELF / {sub(/,$/,"",$6); printf("%s",$6);} / (i[3456]86|x86_64)$/ {printf("%s ",$NF);}'); do
				case "${__JWALTER_DISTBIN_LIB}" in
					x86_64|x86-64|amd64)
						__JWALTER_DISTBIN_LIB="x86_64"
						;;
					x86|x86_32|x32|i386|i486|i586|i686)
						__JWALTER_DISTBIN_LIB="x86"
						;;
				esac
				if ! grep -qE "\\b${__JWALTER_DISTBIN_LIB}\\b" <<<"${__JWALTER_DISTBIN_LIBS[*]}"; then
					__JWALTER_DISTBIN_LIBS+=("${__JWALTER_DISTBIN_LIB}")
					__JWALTER_DISTBIN_PATHS+=("${HOME}/${__JWALTER_DISTBIN_PATH}/${__JWALTER_DISTBIN_OS}/${__JWALTER_DISTBIN_LIB}/${__JWALTER_DISTBIN_DISTRO}")
					__JWALTER_DISTBIN_PATHS+=("${HOME}/${__JWALTER_DISTBIN_PATH}/${__JWALTER_DISTBIN_OS}/${__JWALTER_DISTBIN_LIB}/${__JWALTER_DISTBIN_DISTRO}/${__JWALTER_DISTBIN_RELEASE}")
				fi
			done
		fi
	done
fi

for __JWALTER_DISTBIN_PATH in "${__JWALTER_DISTBIN_PATHS[@]}"; do
	if [ "${__JWALTER_DISTBIN_PATH_POSITION}" = "first" ]; then
		PATH="${__JWALTER_DISTBIN_PATH}:${PATH}"
	else
		PATH="${PATH}:${__JWALTER_DISTBIN_PATH}"
	fi
done

unset __JWALTER_DISTBIN_ARCH __JWALTER_DISTBIN_OS __JWALTER_DISTBIN_DISTRO __JWALTER_DISTBIN_RELEASE __JWALTER_DISTBIN_LIBS __JWALTER_DISTBIN_LIB __JWALTER_DISTBIN_LINKERS __JWALTER_DISTBIN_LINKER
export PATH
