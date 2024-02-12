# =============================================================================
# OpenWRT Dynamic DNS
# A simple script to update dynamic DNS
# Supported providers: porkbun
# Requires curl and jq
# =============================================================================

echo $( date )
source ./provider.conf

if [ "${#SUBDOMAIN}" -gt 0 ] ;then
        SUBDOMAIN="/$SUBDOMAIN"
fi

TMPFILE=$( mktemp )

EXT=$( ip ad show dev $WAN | grep "inet " | cut -d ' ' -f 6 | cut -d '/' -f 0 )

echo "  WAN: $EXT"

echo "  Checking DDNS provider:"
curl -s -H "Content-Type: application/json" --data "$GETDATA" "$GETURL" > $TMPFILE
CHECK=$( jq -r '.records[] | .content ' $TMPFILE )
VALIDADR=$( echo "$CHECK" | grep -Eo '^(([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))\.){3}([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))$' )

if [ -n "$VALIDADR" ]; then
    echo "    Found valid IP address"
else
    echo "    BAD ADDRESS: $CHECK"
    echo "  Failed to get remote address."
    rm $TMPFILE
    exit 1
fi

echo "  Got: $CHECK"

if [ "$EXT" = "$CHECK" ]; then
        echo "  Nothing to do. Addresses match."
else
        echo "  Updating DNS"
        SETDATA="$SETDATA, \"content\": \"$EXT\" }"
        curl -s -H "Content-Type: application/json" --data "$SETDATA" "$SETURL" > $TMPFILE
        SETRESULT=$( jq -r ".status" $TMPFILE )
        echo "  $SETRESULT"
fi

rm $TMPFILE
echo "Done."
