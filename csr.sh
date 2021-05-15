#!/usr/bin/env bash
set -eu

show_help() {
  printf 'Usage:\n'\
'  %s --key <keyfile>\n'\
'  [--cnf <cnffile>]\n'\
'  [--out <outfile>]\n'\
  "$0"
  printf 'Tips:\n  Create key first: openssl genrsa -out mycert.key 2048\n'
}

keyfile=
outfile=
cnffile=
passargs=()
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
    --cnf)
      cnffile="$2"
      shift ; shift
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      passargs+=("$1")
      shift
      ;;
  esac
done

if ! [ -f "$keyfile" ] ; then
  show_help
  exit 1
fi

if [ -z "$outfile" ] ; then
  csrfile="${keyfile}.csr"
else
  csrfile="${outfile}"
fi

if [ -f "$csrfile" ] ; then
  echo "csrfile exists: $csrfile"
  exit 1
fi

if [ -z "$cnffile" ] ; then
  cnffile="${csrfile}.cnf"
fi

if ! [ -r "$cnffile" ] ; then
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
# Create the openssl configuration file. This is used for both generating
# the certificate as well as for specifying the extensions. It aims in favor
# of automation, so the DN is encoding and not prompted.
cat > "$cnffile" << EOF
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
fi

openssl req -new -config "$cnffile" -key "$keyfile" -out "$csrfile"
