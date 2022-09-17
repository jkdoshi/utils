#!/usr/bin/env bash

#CREDIT: https://gist.github.com/Tras2/cba88201b17d765ec065ccbedfb16d9a

# A bash script to update a Cloudflare DNS A record with the external IP of
# the source machine.
# Used to provide DDNS service for my home.
# Needs the DNS record pre-creating on Cloudflare

# Proxy - uncomment and provide details if using a proxy
#export https_proxy=http://<proxyuser>:<proxypassword>@<proxyip>:<proxyport>

# load config
env=$(dirname $0)/.env
if [ \! -f $env ]; then
  echo "Not found: $env"
  exit 1
fi

source $(dirname $0)/.env

# dnsrecord is the A record which will be updated
dnsrecord=$(hostname).${zone}
# the above assumes the current host is just "myhost" part of "myhost.domain.com"

# Get the current external IP address
ip=$(curl -s -X GET https://checkip.amazonaws.com)

# echo "Current IP is $ip"

found=$(host office3.spinspire.com 1.1.1.1 | sed -n 's/^.* has address \(.*\)$/\1/ p')
if [ "$ip" = "$found" ] ; then
  # echo "$dnsrecord is currently set to $ip; no changes needed"
  exit
else
  echo $(date) "DNS IP=$found, my IP=$ip, updating ..."
fi

# if here, the dns record needs updating

# get the zone id for the requested zone
zoneid=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$zone&status=active" \
  -H "X-Auth-Email: $cloudflare_auth_email" \
  -H "X-Auth-Key: $cloudflare_auth_key" \
  -H "Content-Type: application/json" | jq -r '{"result"}[] | .[0] | .id')

# echo "Zoneid for $zone is $zoneid"

# get the dns record id
dnsrecordid=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zoneid/dns_records?type=A&name=$dnsrecord" \
  -H "X-Auth-Email: $cloudflare_auth_email" \
  -H "X-Auth-Key: $cloudflare_auth_key" \
  -H "Content-Type: application/json" | jq -r '{"result"}[] | .[0] | .id')

# echo "DNSrecordid for $dnsrecord is $dnsrecordid"

# update the record
curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zoneid/dns_records/$dnsrecordid" \
  -H "X-Auth-Email: $cloudflare_auth_email" \
  -H "X-Auth-Key: $cloudflare_auth_key" \
  -H "Content-Type: application/json" \
  --data "{\"type\":\"A\",\"name\":\"$dnsrecord\",\"content\":\"$ip\",\"ttl\":1,\"proxied\":false}" | jq
