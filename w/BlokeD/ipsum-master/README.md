![Logo](https://i.imgur.com/PyKLAe7.png)

[![License](https://img.shields.io/badge/license-The_Unlicense-red.svg)](https://unlicense.org/)

About
----

**IPsum** is a threat intelligence feed based on 30+ different publicly available [lists](https://github.com/stamparm/maltrail) of suspicious and/or malicious IP addresses. All lists are automatically retrieved and parsed on a daily (24h) basis and the final result is pushed to this repository. List is made of IP addresses together with a total number of (black)list occurrence (for each). Greater the number, lesser the chance of false positive detection and/or dropping in (inbound) monitored traffic. Also, list is sorted from most (problematic) to least occurent IP addresses.

As an example, to get a fresh and ready-to-deploy auto-ban list of "bad IPs" that appear on at least 3 (black)lists you can run:

```
curl https://raw.githubusercontent.com/stamparm/ipsum/master/ipsum.txt 2>/dev/null | grep -v "#" | grep -v -E "\s[1-2]$" | cut -f 1
```

If you want to try it with `ipset`, you can do the following:

```
sudo su
apt-get -qq install iptables ipset
ipset -q flush ipsum
ipset -q create ipsum hash:ip
for ip in $(curl https://raw.githubusercontent.com/stamparm/ipsum/master/ipsum.txt 2>/dev/null | grep -v "#" | grep -v -E "\s[1-2]$" | cut -f 1); do ipset add ipsum $ip; done
iptables -D INPUT -m set --match-set ipsum src -j DROP 2>/dev/null
iptables -I INPUT -m set --match-set ipsum src -j DROP
```

In directory [levels](levels) you can find preprocessed raw IP lists based on number of blacklist occurrences (e.g. [levels/3.txt](levels/3.txt) holds IP addresses that can be found on 3 or more blacklists).

Wall of Shame (2025-04-25)
----

|IP|DNS lookup|Number of (black)lists|
|---|---|--:|
218.92.0.220|-|10
218.92.0.228|-|10
180.178.94.73|-|9
183.162.197.57|-|9
218.92.0.111|-|9
218.92.0.198|-|9
218.92.0.216|-|9
218.92.0.217|-|9
218.92.0.218|-|9
218.92.0.219|-|9
218.92.0.221|-|9
218.92.0.222|-|9
218.92.0.223|-|9
218.92.0.225|-|9
218.92.0.226|-|9
218.92.0.227|-|9
218.92.0.229|-|9
218.92.0.230|-|9
218.92.0.231|-|9
218.92.0.232|-|9
218.92.0.233|-|9
218.92.0.235|-|9
218.92.0.236|-|9
218.92.0.237|-|9
45.148.10.67|-|8
92.118.39.61|-|8
103.70.114.33|-|8
103.70.115.15|-|8
103.197.184.115|-|8
103.197.184.162|-|8
103.197.184.219|-|8
134.209.120.69|-|8
160.19.78.241|-|8
160.19.78.242|-|8
160.19.78.247|-|8
160.19.79.72|-|8
160.19.79.239|-|8
160.191.52.76|-|8
160.191.52.79|-|8
160.191.52.81|-|8
160.191.52.84|-|8
193.32.162.89|-|8
196.251.69.43|-|8
196.251.69.116|-|8
196.251.70.234|-|8
196.251.83.136|undefined.hostname.localhost|8
196.251.87.35|-|8
196.251.87.42|-|8
196.251.87.45|-|8
196.251.87.74|-|8
218.92.0.103|-|8
47.74.40.171|-|8
80.94.95.115|-|7
89.248.172.16|house.census.shodan.io|7
92.118.39.57|-|7
92.118.39.65|-|7
92.118.39.90|-|7
92.118.39.97|-|7
103.70.114.87|-|7
103.70.115.6|-|7
103.70.115.38|-|7
103.197.184.12|-|7
103.197.184.167|-|7
160.191.52.73|-|7
162.142.125.115|scanner-19.ch1.censys-scanner.com|7
167.94.145.107|-|7
193.233.165.245|-|7
195.178.110.26|-|7
196.251.66.3|-|7
196.251.66.71|-|7
196.251.67.42|-|7
196.251.85.34|-|7
196.251.85.62|-|7
196.251.87.54|-|7
115.190.14.221|-|7
160.191.89.4|-|7
212.18.104.18|56446.ip-ptr.tech|7
45.148.10.79|-|7
59.53.92.190|-|7
92.118.39.68|-|7
