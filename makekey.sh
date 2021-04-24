#!/usr/bin/env bash
set -eu

show_help() {
  echo "$0 --out <outfile> --bits [bits, default 2048]"
}

outfile=
bits=2048
while [ "$#" -gt 0 ] ; do
  case "$1" in
    --out)
      outfile=$2
      shift ; shift
      ;;
    --bits)
      bits=$2
      shift ; shift
      ;;
    *)
      show_help
      exit 1
      shift
      ;;
  esac
done

if [ -z "$outfile" ] ; then
  show_help
  exit 1
fi

openssl genrsa -out "$outfile" "$bits"
