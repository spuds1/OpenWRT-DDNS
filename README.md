# OpenWRT Dynamic DNS

A simple script to update dynamic DNS.

Requires curl. Use cron to schedule the update.

If the cache has an invalid address, it will be deleted and a new cache file created on the next iteration.

Supported providers:
- porkbun
