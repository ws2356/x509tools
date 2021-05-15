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
ca_sh="${this_dir}/ca.sh"

show_help() {
  printf 'Usage:\n'\
'  %s --csr <csrfile>\n'\
'  [--cnf <cnffile>]\n'\
'  [--out <outfile>]\n'\
  "$0"
}

csrfile=
cnffile=
outfile=
passargs=()
cadir=
while [ "$#" -gt 0 ] ; do
  case "$1" in
    --csr)
      csrfile="$2"
      shift ; shift
      ;;
    --cnf)
      cnffile="$2"
      shift ; shift
      ;;
    --out)
      outfile="$2"
      shift ; shift
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      if [ "$1" = "--cadir" ] && [ $# -gt 1 ] ; then
        cadir="$2"
      fi
      passargs+=("$1")
      shift
      ;;
  esac
done

if ! [ -r "$csrfile" ] ; then
  show_help
  exit 1
fi

if [ -z "$outfile" ] ; then
  crtfile="${csrfile}.crt"
else
  crtfile="$outfile"
fi

if [ -f "$crtfile" ] ; then
  echo "crtfile exist: $crtfile"
  exit 1
fi

extension_args=()
if [ -n "$cnffile" ] ; then
  extension_args+=("-extensions" "v3_req" "-extfile" "$cnffile")
fi

"$ca_sh" -in "$csrfile" -out "$crtfile" -create_serial "${passargs[@]}" "${extension_args[@]}"
