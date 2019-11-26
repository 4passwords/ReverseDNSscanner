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
syntax: scanmethod rangevalue -nodnssuffix dnsservers runtype

___scanmethod values : subnet,iprange
___rangevalue values : x.x.x.x/yy, x.x.x.x-y.y.y.y
___domainsuffix values : domain.local,-nodnssuffix
___dnsservers values : x.x.x.x, y.y.y.y
___operating system value : windows,esxi,aix,linux
___runtype value : execute,testdata

````
Call the script with the required script arguments without parameternames, only the values in the correct order, scanmethod, rangevalue, domainsuffix or -nodnssuffix 
and dnsservers. 
The ip range is splitted with an -, the subnet with an / and the dns servers with a , if multiple dns servers are supplied.

#Discovery output example

```
Machine           OperatingSystem DistinguishedName                  
-------           --------------- -----------------                  
testcomputername1 windows         C=testcomputername1,OU=127.0.0.0/24
```

#discovery test implementation

- add the script in thycotic under scripts
- add to the discovery scanners a machine scanner with a nane, powershell discovery, hostrange as input template, output template computer, and as script the new powershell script. 
-- as script arguments 
```
subnet $target -nodnssuffix dnsserver1,dnsserver2 OStypename execute
```
- add a new disovery source
- add a manual host range and add a subnet or range (make sure the script has the correct arguments like iprange or subnet
- add the machine scanner, make sure the user attached can execute as user on the DE or the webserver powershell scripts
- add as find accounts the unix user or any other desired account detect method






