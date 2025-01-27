# Define constants
:local TOKEN CF_Token
:local ZONEIDv6 CF_Zone_ID
:local RECORDIDv6 CF_Record_ID
:local RECORDNAMEv6 Your_Domain
:local WANIF ether1
:local IPV6POOL telstra
:local currentIP ""
:local resolvedIP ""

# Log info
:log info "DDNS updates checking..."

# Fetch the Resolved IPv6 address via DNS
:set resolvedIP [:resolve domain-name=$RECORDNAMEv6 type=ipv6 server=1.1.1.1]; #set server your local DNS provider

# Check if WAN interface is running 
:local wanRunning [/interface get [find name=$WANIF] running];

:if ($wanRunning) do={ 

    # Get the IPv6 address from the WAN interface
    :local varIP [/ipv6/address get [find global interface=$WANIF && from-pool=$IPV6POOL] address];
    # Extract the IPv6 address (remove the / prefix)
    :set currentIP [:pick $varIP 0 [:find $varIP "/"]]

 } else {

    :log warning "WAN interface $WANIF does not have a public IPv6 address or is not running."
    :local "currentIP" ""
 };

# Compare the current IPv6 address with the resolved one
:if ($currentIP != "" && $currentIP != $resolvedIP) do={ 

    # Update the DNS record and send a notification

    # Construct the Cloudflare API URL
    :local url "https://api.cloudflare.com/client/v4/zones/$ZONEIDv6/dns_records/$RECORDIDv6/" #check CF API
    
    # Call the Cloudflare API to update the DNS record
    :local cfapi [/tool fetch http-method=put mode=https url=$url check-certificate=no output=user as-value \
        http-header-field="Authorization: Bearer $TOKEN" \
        http-data="{\"type\":\"AAAA\",\"name\":\"$RECORDNAMEv6\",\"content\":\"$currentIP\",\"ttl\":120,\"proxied\":false}"]
    
    # Log the information about updating the DNS record
    :log info "CF-DDNS: $RECORDNAMEv6 is now updated with $currentIP."
 } else {

    # If the addresses are the same, log the information
    :log info "CF-DDNS: No change in IP address ($currentIP)."

};
