# 4Passwords / Thycotic Secret Server Discovery toolbox : Reverse DNS scanner
# v1.5.1

This powershell script is a script to list a list of servers forma reverse dns lookup on a range/subnet and on a given set of dns servers
the output will be in the format needed to be used in the advanced discovery and or a extensible discovery.

The scripts features are:

- Generate a list of servernames with or without a dns prefix.
- output is usable in the discovery of Thycotic
- scan by range or subnet
- do test run or test data

TODO improvements:

- TODO-Improvement: Dynamicly fetch or detect the operating system

```powershell
syntax: scanmethod rangevalue domainsuffix dnsservers osvalue runtype
_
_
_
___scanmethod values : subnet,iprange
___rangevalue values : x.x.x.x/yy, x.x.x.x-y.y.y.y
___domainsuffix values : domain.local
___dnsservers values : x.x.x.x, y.y.y.y
___operating system value : windows,esxi,aix,linux
___runtype value : execute,testdata
_
_
_
Call the script with the required script arguments without parameternames, only the values in the correct order, scanmethod, rangevalue, domainsuffix and dnsservers. 
The ip range is splitted with an -, the subnet with an / and the dns servers with a , if multiple dns servers are supplied.
_
_
_
````

t






