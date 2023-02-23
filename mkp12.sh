#!/usr/bin/env bash
set -eu

show_help() {
  echo "$0 --cert <cert> --key <keyfile> --out <outfile>"
}

relay_args=()
certfile=
keyfile=
outfile=
while [ "$#" -gt 0 ] ; do
  case "$1" in
    --cert)
      certfile=$2
      shift ; shift
      ;;
    --key)
      keyfile=$2
      shift ; shift
      ;;
    --out)
      outfile=$2
      shift ; shift
      ;;
    *)
      relay_args+=("$1")
      shift
      ;;
  esac
done

if [ -z "$certfile" ] || [ -z "$keyfile" ] ; then
  show_help
  exit 1
fi

if [ -z "$outfile" ] ; then
  outfile="${certfile}.p12"
fi

openssl pkcs12 -export -in "$certfile"  -inkey "$keyfile" -out "$outfile" "${relay_args[@]}"
