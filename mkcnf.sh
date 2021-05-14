#!/usr/bin/env bash
set -eu

cadir=
while [ "$#" -gt 0 ] ; do
  case "$1" in
    --cadir)
      cadir="$2"
      break
      ;;
    *)
      shift
      ;;
  esac
done

if ! [ -d "$cadir" ] ; then
  echo "no cadir" >&2
  exit 1
fi

cadb="${cadir}/index.txt"
cadb_attr="${cadir}/index.txt.attr"
[ -r "$cadb" ] || touch "$cadb"
[ -r "$cadb_attr" ] || touch "$cadb_attr"

cnf_file="$(mktemp)"
cat > "$cnf_file" << EOF
[ ca ]
default_ca	= CA_default		# The default ca section

[ CA_default ]
default_md	= default		# use public key default MD
dir             = "$cadir"              # Where everything is kept
certs           = $cadir/certs            # Where the issued certs are kept
crl_dir         = $cadir/crl              # Where the issued crl are kept
database        = $cadir/index.txt        # database index file.
#unique_subject = no                    # Set to 'no' to allow creation of
                                        # several certs with same subject.
new_certs_dir   = $cadir/newcerts         # default place for new certs.

certificate     = $cadir/cacert.pem       # The CA certificate
serial          = $cadir/serial           # The current serial number
crlnumber       = $cadir/crlnumber        # the current crl number
                                        # must be commented out to leave a V1 CRL
crl             = $cadir/crl.pem          # The current CRL
private_key     = $cadir/private/cakey.pem# The private key

default_days	= 365			# how long to certify for
default_crl_days= 30			# how long before next CRL
default_md	= default		# use public key default MD
preserve	= no			# keep passed DN ordering

EOF

printf %s "$cnf_file"
