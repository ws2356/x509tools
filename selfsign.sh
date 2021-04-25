#!/usr/bin/env bash
set -eu

show_help() {
  echo "$0 --key <keyfile> --out <outfile>"
}

keyfile=
outfile=
days=365
while [ "$#" -gt 0 ] ; do
  case "$1" in
    --key)
      keyfile="$2"
      shift ; shift
      ;;
    --out)
      outfile="$2"
      shift ; shift
      ;;
    --days)
      days="$2"
      shift ; shift
      ;;
    *)
      show_help
      exit
      shift
      ;;
  esac
done

if ! [ -f "$keyfile" ]  ; then
  show_help
  exit 1
fi

if [ -z "$outfile" ] ; then
  outfile="${keyfile}.ca.crt.pem"
fi

openssl req -new -x509 -days "$days" -key "$keyfile"  -out "$outfile"
