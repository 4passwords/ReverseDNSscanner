# by: jan@mccs.nl
# https://github.com/4passwords/ReverseDNSscanner

precleanup.
#

if ($scanmethod -ne $null) { remove-variable scanmethod }
if ($rangevalue-ne $null) { remove-variable rangevalue }
if ($domainsuffix -ne $null) { remove-variable domainsuffix }
if ($dnsservers -ne $null) { remove-variable dnsservers }
if ($osvalue -ne $null) { remove-variable osvalue }
if ($runtype -ne $null) { remove-variable runtype }

# basic functions

Function exiterrorsyntax
{
write-error @"
_
_
_
syntax: scanmethod rangevalue -nodnssuffix dnsservers runtype
_
_
_
___scanmethod values : subnet,iprange
___rangevalue values : x.x.x.x/yy, x.x.x.x-y.y.y.y
___domainsuffix values : domain.local,-nodnssuffix
___dnsservers values : x.x.x.x, y.y.y.y
___operating system value : windows,esxi,aix,linux
___runtype value : execute,testdata
_
_
_
Call the script with the required script arguments without parameternames, only the values in the correct order, scanmethod, rangevalue, domainsuffix or -nodnssuffix and dnsservers. 
The ip range is splitted with an -, the subnet with an / and the dns servers with a , if multiple dns servers are supplied.
_
_
_
"@ -Category SyntaxError
exit 1
}

# basic script checks , note: parameters doe not work in thycotic discovery thats why the old method is used.

if ( $args.Count -ge "6" ) 
{
} else {
exiterrorsyntax
}


if ($scanmethod -eq $null) { $scanmethod = $args[0]; }
$validatescanmethod = "unchecked" 
switch (($scanmethod).tolower())
{
    subnet { $validatescanmethod = "hit" }
    iprange { $validatescanmethod = "hit" }
}

if ( $validatescanmethod -eq "unchecked" )
{
echo 1
exiterrorsyntax
}


if ($rangevalue-eq $null) { $rangevalue = $args[1]; }
if ($domainsuffix -eq $null) { $domainsuffix = $args[2]; }
if ($dnsservers -eq $null) { $dnsservers = $args[3]; }
if ($osvalue -eq $null) { $osvalue = $args[4]; }
if ($runtype -eq $null) { $runtype = $args[5]; }

# remove the OU= value if added by Thycotic Secret Server from the $target option
$rangevalue = $rangevalue.replace("OU=","")


# params are not compatible with the powershell scripting as they are put into a wrapper by thycotic.
#
#if ($ComputersinIPRANGE -ne $null) { remove-variable ComputersinIPRANGE }
#if ($FoundComputers -ne $null) { remove-variable FoundComputers }
#param 
#( 
#  [ValidateNotNullOrEmpty()][Parameter(Mandatory=$true,ValueFromPipeline=$true,HelpMessage = "Enter the values iprange or subnet (iprange to scan for a range or subnet to scan with a subnet and prefix.)")][ValidateSet("iprange","subnet")][string]$scanmethod, 
#  [ValidateNotNullOrEmpty()][Parameter(Mandatory=$true,ValueFromPipeline=$true,HelpMessage = "Enter the subnet/prefix (10.10.100.10/24) or the iprange 10.10.100.10-10.10.100.12. do remember to use the correct range that is matching iprange or subnet option!")][string]$rangevalue, 
#  [ValidateNotNullOrEmpty()][Parameter(Mandatory=$true,ValueFromPipeline=$true,HelpMessage = "Enter the domainname that will be used")][string]$domainsuffix
#)

write-debug "scanmethod:$scanmethod"
write-debug "rangevalue:$rangevalue"
write-debug "domainsuffix:$domainsuffix"
write-debug "dnsservers:$dnsservers"
write-debug "runtype:$runtype" 

if ( $scanmethod.ToLower() -eq 'subnet' )
{
$ipsubnet=$rangevalue.split("/") | select -First 1
$cidrvalue=$rangevalue.split("/") | select -Last 1

write-debug "ipsubnet:$ipsubnet"
write-debug "cidrvalue:$cidrvalue"

if ( $ipsubnet -eq $cidrvalue ) {
write-error "this does not seem like a subnet with a prefix: x.x.x.x/yy try adjusting the value or switch the scanmethod" 
write-error "given value: $ipsubnet" 
exit 1
}

}

if ( $scanmethod.ToLower() -eq 'iprange' )
{
$iprangestart=$rangevalue.split("-") | select -First 1
$iprangestop=$rangevalue.split("-") | select -Last 1
#$ipdot1=$($iprangestart.split(".")  | Select -first 1)
#$ipdot2=$($iprangestart.split(".") |select -skip 1 | Select -first 1)
#$ipdot3=$($iprangestart.split(".") |select -skip 2 | Select -first 1)
#$ipdot4=$iprangestop
#$iprangestop="$ipdot1.$ipdot2.$ipdot3.$ipdot4"

write-debug "iprangestart:$iprangestart"
write-debug "iprangestop:$iprangestop"

if ( $iprangestart -eq $iprangestop ) {
write-error "this does not seem like an iprange : x.x.x.x-y.y.y.y, try adjusting the value or switch the scanmethod" 
write-error "given value: $iprangestart" 
exit 1
}

}


Function resolvehost
{

if ( $args.Count -ge "2" ) 
{
} else {
write-error "syntax: ip domainsuffix" 
exit 1
}

if ($ip -eq $null) { $ip = $args[0]; }
if ($domain -eq $null) { $domain = $args[1]; }
$Hashdnsresults = [ordered]@{}
$nameservers=@(($dnsservers.Split(",")))
#$dnsservers.Split(",")
#echo $nameservers

#switch ( ($domain).ToLower() )
#{
#    xxxx.corp { $nameservers=@( "10.10.100.10", "10.10.100.11" ) } 
#    idm.xxx.corp { $nameservers=@( "10.10.100.36", "10.10.100.37" ) } 
#    default { $nameservers=@( "10.10.100.10", "10.10.100.11" ) } 
#}
$DebugPreference = 'SilentlyContinue'
foreach ($nameserver in $nameservers) 
{
    try {
        $Hashdnsresults.$nameserver = Resolve-DnsName -ErrorAction SilentlyContinue -Name $ip -Type PTR -Server $nameserver -NoHostsFile -Dnsonly -QuickTimeout | select -Property Type, NameHost | where {$_.Type -eq "PTR"}  | select -Property NameHost | select -First 1 
    }
    catch {
     #Error reporting/logging
    }
}
$DebugPreference = 'Continue'
$countdnshit=($Hashdnsresults.Values | sort | Get-Unique | measure).Count
# count the values from the name servers # if more then 1 then its outofsync
#if ( $countdnshit -ge 2 )
#    {
#    return $("$ip-DNSERR-MISMATCH")
#    } 

#if ( $countdnshit -eq 0 )
#    {
#    return $("$ip-DNSERR-NOREVLOOKUP")
#    } 
if ( $countdnshit -eq 1 )
    {
            #write-debug $((($Hashdnsresults.Values | sort | Get-Unique).NameHost).ToUpper().Split('.')[0])
            return $((($Hashdnsresults.Values | sort | Get-Unique).NameHost).ToUpper().Split('.')[0])
     } 

#write-host $returnvalue

    if ($countdnshit -ne $null) { remove-variable countdnshit }
    #if ($ip -ne $null) { Remove-variable ip }
    if ($domain -ne $null) { Remove-variable domain }
    if ($countdnshit -ne $null) { Remove-variable countdnshit }
    if ($Hashdnsresults -ne $null) { Remove-variable Hashdnsresults }
    if ($nameserver -ne $null) { Remove-Variable nameserver } 
    if ($nameservers -ne $null) { Remove-Variable nameservers }  
}



function Get-IPrange
{
<# 
  .SYNOPSIS  
    Get the IP addresses in a range 
  .EXAMPLE 
   Get-IPrange -start 192.168.8.2 -end 192.168.8.20 
  .EXAMPLE 
   Get-IPrange -ip 192.168.8.2 -mask 255.255.255.0 
  .EXAMPLE 
   Get-IPrange -ip 192.168.8.3 -cidr 24 
#> 
 
param 
( 
  [string]$start, 
  [string]$end, 
  [string]$ip, 
  [string]$mask, 
  [int]$cidr 
) 
 
function IP-toINT64 () { 
  param ($ip) 
 
  $octets = $ip.split(".") 
  return [int64]([int64]$octets[0]*16777216 +[int64]$octets[1]*65536 +[int64]$octets[2]*256 +[int64]$octets[3]) 
} 
 
function INT64-toIP() { 
  param ([int64]$int) 

  return (([math]::truncate($int/16777216)).tostring()+"."+([math]::truncate(($int%16777216)/65536)).tostring()+"."+([math]::truncate(($int%65536)/256)).tostring()+"."+([math]::truncate($int%256)).tostring() )
} 
 
if ($ip) {$ipaddr = [Net.IPAddress]::Parse($ip)} 
if ($cidr) {$maskaddr = [Net.IPAddress]::Parse((INT64-toIP -int ([convert]::ToInt64(("1"*$cidr+"0"*(32-$cidr)),2)))) } 
if ($mask) {$maskaddr = [Net.IPAddress]::Parse($mask)} 
if ($ip) {$networkaddr = new-object net.ipaddress ($maskaddr.address -band $ipaddr.address)} 
if ($ip) {$broadcastaddr = new-object net.ipaddress (([system.net.ipaddress]::parse("255.255.255.255").address -bxor $maskaddr.address -bor $networkaddr.address))} 
 
if ($ip) { 
  $startaddr = IP-toINT64 -ip $networkaddr.ipaddresstostring 
  $endaddr = IP-toINT64 -ip $broadcastaddr.ipaddresstostring 
} else { 
  $startaddr = IP-toINT64 -ip $start 
  $endaddr = IP-toINT64 -ip $end 
} 
 
 
for ($i = $startaddr; $i -le $endaddr; $i++) 
{ 
  INT64-toIP -int $i 
}

}




#if ($Ou -eq $null) { $Ou = $args[0]; }
#if ($domain -eq $null) { $domain = $args[1]; }

#write-debug "($Ou),domain:$domain" 



#write-debug "domain: $domain"
#write-debug "searchbase: $searchbase"

switch ($runtype.Tolower()) 

{

    'execute'
        {
            $FoundComputers = @()

            if ( $scanmethod.ToLower() -eq 'subnet' )
            {
            $ComputersinIPRANGE = $(Get-IPrange -ip $ipsubnet -cidr $cidrvalue )
            }

            if ( $scanmethod.ToLower() -eq 'iprange' )
            {
            $ComputersinIPRANGE = $(Get-IPrange -start $iprangestart -end $iprangestop)
            }

            $hostname=$null
            foreach ($IP in $ComputersinIPRANGE)
            {
              $hostname = resolvehost $IP $domainsuffix 
  
              if ($hostname -ne $null)
              {
              $object = New-Object –TypeName PSObject;
              if ($domainsuffix -eq "-nodnssuffix") { 
              $object | Add-Member -MemberType NoteProperty -Name Machine -Value ($hostname);
              } else {
              $object | Add-Member -MemberType NoteProperty -Name Machine -Value ($hostname + "." + $domainsuffix);
              }
              $object | Add-Member -MemberType NoteProperty -Name OperatingSystem -Value $osvalue
                $object | Add-Member -MemberType NoteProperty -Name DistinguishedName -Value ("C=" + $hostname + "," + "OU=" + $rangevalue)
              #$object | Add-Member -MemberType NoteProperty -Name IP -Value $IP;
              $FoundComputers +=$object;
              }

            }
            return $FoundComputers
            }


'testdata'
        {
             $dummyname = $null 
             $FoundComputers = @()
             $ComputersinIPRANGE = @( "testcomputername1", "testcomputername2" )

             foreach ($dummyname in $ComputersinIPRANGE)
            {
              $hostname = $dummyname 
  
              if ($hostname -ne $null)
              {
              $object = New-Object –TypeName PSObject;
                  if ($domainsuffix -eq "-nodnssuffix") { 
              $object | Add-Member -MemberType NoteProperty -Name Machine -Value ($hostname);
     
              } else {
                     $object | Add-Member -MemberType NoteProperty -Name Machine -Value ($hostname + "." + $domainsuffix);
              }
              $object | Add-Member -MemberType NoteProperty -Name OperatingSystem -Value $osvalue

  $object | Add-Member -MemberType NoteProperty -Name DistinguishedName -Value ("C=" + $hostname + "," + "OU=" + $rangevalue)
              #$object | Add-Member -MemberType NoteProperty -Name IP -Value $IP;
              $FoundComputers +=$object;
             }
            return $FoundComputers
           
        }


    }
        
}

# args: $target $[1]$domain
