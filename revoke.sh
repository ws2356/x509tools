#!/usr/bin/env bash
set -eu

this_file="${BASH_SOURCE[0]}"
if ! [ -e "$this_file" ] ; then
  this_file="$(type -p "$this_file")"
fi
if ! [ -e "$this_file" ] ; then
  echo "Failed to resolve file."
  exit 1
fi
if ! [[ "$this_file" =~ ^/ ]] ; then
  this_file="$(pwd)/$this_file"
fi
while [ -h "$this_file" ] ; do
    ls_res="$(ls -ld "$this_file")"
    link_target=$(expr "$ls_res" : '.*-> \(.*\)$')
    if [[ "$link_target" =~ ^/ ]] ; then
      this_file="$link_target"
    else
      this_file="$(dirname "$this_file")/$link_target"
    fi
done
this_dir="$(dirname "$this_file")"
show_help() {
  printf 'Usage:\n'\
'  %s --crt <crtfile>\n'\
  "$0"
}

ca_sh="${this_dir}/ca.sh"

passargs=()
crtfile=
while [ "$#" -gt 0 ] ; do
  case "$1" in
    --crt)
      crtfile="$2"
      shift ; shift
      ;;
    *)
      passargs+=("$1")
      shift
      ;;
  esac
done

if [ -z "$crtfile" ] ; then
  show_help
  exit 1
fi

"$ca_sh" -revoke "$crtfile" "${passargs[@]}"
