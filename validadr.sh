verifyaddress () {
    # Verify format
    VALIDADR=$( echo "$1" | grep -Eo '^(([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))\.){3}([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))$' )

    # Check actual address
    if [ -n "$VALIDADR" ]; then
        OCT1=$( echo $1 | cut -d '.' -f 1 )        
        OCT2=$( echo $1 | cut -d '.' -f 2 )
        OCT3=$( echo $1 | cut -d '.' -f 3 )
        OCT4=$( echo $1 | cut -d '.' -f 4 )

        # Ignore 0, private addresses and link-local
        if [[ $OCT1 = 0 ]]; then return 2; fi
        if [[ $OCT1 = 10 ]]; then return 2; fi
        if [[ $OCT1 = 127 ]]; then return 2; fi
        if [[ $OCT1 = 192 ]] && [[ $OCT2 = 168 ]]; then return 2; fi
        if [[ $OCT1 = 169 ]] && [[ $OCT2 = 254 ]]; then return 2; fi
        if [[ $OCT1 = 172 ]] && [[ $OCT2 -ge 16 ]] && [[ $OCT2 -le 31 ]]; then return 2; fi

        #/24
        BAD=$( echo "192.0.0 192.0.2 192.31.196 192.52.193 192.88.89 192.175.48 198.51.100 203.0.113" | tr " " "\n" )
        for ADDR in $BAD
        do
            if [[ "$OCT1.$OCT2.$OCT3" = "$ADDR" ]]; then return 2; fi
        done

        #/32
        BAD=$( echo "192.0.0.8 192.0.0.9 192.0.0.170 192.0.0.171 255.255.255.255" | tr " " "\n" )
        for ADDR in $BAD
        do
            if [[ "$OCT1.$OCT2.$OCT3.$OCT4" = "$ADDR" ]]; then return 2; fi
        done

        return 0
    else
        # Bad format
        return 1
    fi
}

# Not handled
# 100.64.0.0/10
# 172.16.0.0/12
# 192.0.0.0/29
# 198.18.0.0/15
# 240.0.0.0/4