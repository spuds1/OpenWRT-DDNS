# =============================================================================
# OpenWRT Dynamic DNS
# A simple script to update dynamic DNS
# Supported providers: porkbun
# Requires curl
# =============================================================================

echo $( date )
source ./validadr.sh
source ./provider.conf

# Cached result from provider
CACHEFILE=/tmp/tmp.oddns
# Address from provider
CHECKADR=
CACHEADR=
# The current day
CURDATE=$( date "+%Y%m%d" )

# Get the WAN address
EXT=$( ip ad show dev $WAN | grep "inet " | cut -d ' ' -f 6 | cut -d '/' -f 0 )

echo "  WAN: $EXT"
verifyaddress "$EXT"
VALIDADR=$?

if [[ $VALIDADR -eq 0 ]]; then
    echo "    Valid IP address"
else
    echo "    BAD WAN ADDRESS: $CHECKADR"
    echo "  Failed to get WAN address."
    exit 1
fi

# Check for the cache file
if test -f "$CACHEFILE"; then    
    # Get first line (date)
    CACHEDATE=$( sed '1!d' $CACHEFILE )
    # Get second line (address)
    CACHEADR=$( sed '2!d' $CACHEFILE )

    # Don't update until the date changes
    if [[ "$CURDATE" -eq "$CACHEDATE" ]]; then
        echo "  Cache is up-to-date. Using cache."
        CHECKADR="$CACHEADR"
    else
        echo "  Cache is stale."
    fi
fi

# No address from cache
if [[ -z "$CHECKADR" ]]; then
        echo "  Checking DDNS provider"

        # Get the provider IP address
        CHECKADR=$( curl -s -H "Content-Type: application/json" --data "$GETDATA" "$GETURL" | jsonfilter -e "@.records[0].content" )

        # Save to the cache
        echo "$CURDATE" > $CACHEFILE
        echo "$CHECKADR" >> $CACHEFILE
fi

verifyaddress "$CHECKADR"
VALIDADR=$?

echo "  Provider: $CHECKADR"

if [[ $VALIDADR -eq 0 ]]; then
        echo "    Valid IP address"
        else
        echo "    BAD PROVIDER ADDRESS: $CHECKADR"
        echo "  Failed to get remote address."

        # Cache has bad address
        if [[ -n "$CACHEADR" ]]; then
                echo "  Bad address in cache. Deleting."
                rm $CACHEFILE
        fi

        exit 1
fi

if [[ "$EXT" = "$CHECKADR" ]]; then
        echo "  Nothing to do. Addresses match."
else
        echo "  Updating DNS"
        SETDATA="$SETDATA, \"content\": \"$EXT\" }"
        SETRESULT=$( curl -s -H "Content-Type: application/json" --data "$SETDATA" "$SETURL" | jsonfilter -e "@.status" )
        echo "  $SETRESULT"
        # Invalidate cache
        rm $CACHEFILE
fi

echo "Done."
