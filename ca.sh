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
'  %s --cadir <cadir>\n'\
  "$0"
}

passargs=()
cadir=
opensslbin=
while [ "$#" -gt 0 ] ; do
  case "$1" in
    --cadir)
      cadir="$2"
      shift ; shift
      ;;
    --openssl)
      opensslbin="$2"
      shift ; shift
      ;;
    *)
      passargs+=("$1")
      shift
      ;;
  esac
done

if [ -z "$cadir" ] ; then
  show_help
  exit 1
fi

if ! [ -d "$cadir" ] ; then
  echo "cadir not exist"
  exit 1
fi

cnf_file="$("${this_dir}/mkcnf.sh" --cadir "$cadir")"
selected_openssl="${opensslbin:-openssl}"
"$selected_openssl" ca -config "$cnf_file" "${passargs[@]}"
