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
'  %s --key <keyfile>\n'\
'  --out <outfile>\n'\
  "$0"
  printf 'Tips:\n  Create key first: openssl genrsa -out mycert.key 2048\n'
}

keyfile=
outfile=
passargs=()
cadir=
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

if ! [ -f "$keyfile" ] ; then
  show_help
  exit 1
fi

country=
state=
city=
organization=
common_name=
email=

item=
desc=
for dn_item in country,cn/us... state,province city organization common_name,fullname email ; do
  DFT_IFS="$IFS"
  IFS=, read -r item desc <<<"$dn_item"
  IFS="$DFT_IFS"
  if [ -n "$desc" ] ; then
    echo "Input your ${item} ($desc):"
  else
    echo "Input your ${item}:"
  fi
  read -r input
  eval "${item}=\"$input\""
done

cnf_file="$(mktemp)"

# Create the openssl configuration file. This is used for both generating
# the certificate as well as for specifying the extensions. It aims in favor
# of automation, so the DN is encoding and not prompted.
cat > "$cnf_file" << EOF
[req]
default_bits = 2048
prompt       = no
utf8         = yes
# Speify the DN here so we aren't prompted (along with prompt = no above).
distinguished_name = req_distinguished_name
# Extensions for SAN IP and SAN DNS
req_extensions = v3_req

# Be sure to update the subject to match your organization.
[req_distinguished_name]
C  = $country
ST = $state
L  = $city
O  = $organization
CN = $common_name
emailAddress = $email

# Allow client and server auth. You may want to only allow server auth.
# Link to SAN names.
[v3_req]
basicConstraints     = CA:FALSE
subjectKeyIdentifier = hash
keyUsage             = digitalSignature, keyEncipherment
extendedKeyUsage     = clientAuth, serverAuth
# subjectAltName       = @alt_names

# Alternative names are specified as IP.# and DNS.# for IP addresses and
# DNS accordingly.
# [alt_names]
# IP.1  = 1.2.3.4
# DNS.1 = my.dns.name
EOF

csrfile="${keyfile}.csr"
if [ -z "$outfile" ] ; then
  crtfile="${keyfile}.crt"
else
  crtfile="$outfile"
fi

if [ -f "$csrfile" ] ; then
  echo "csrfile exist: $csrfile"
  exit 1
fi

if [ -f "$crtfile" ] ; then
  echo "crtfile exist: $crtfile"
  exit 1
fi

openssl req -new -config "$cnf_file" -key "$keyfile" -out "$csrfile"
"$ca_sh" -in "$csrfile" -out "$crtfile" -create_serial "${passargs[@]}" -extensions v3_req \
  -extfile "$cnf_file"
