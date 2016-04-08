import-module Update-IniFiles.psm1

$routes = get-netroute -DestinationPrefix 0.0.0.0/0
if ($routes.GetType().IsArray -eq $true)
{
    $interfaceIndex = $routes[0].ifIndex
} else {
    $interfaceIndex = $routes.ifIndex
}

$dnsaddrs = (Get-DnsClientServerAddress -InterfaceIndex $interfaceIndex -AddressFamily IPv4).ServerAddresses
if ($dnsaddrs.GetType().IsArray -eq $true) {
    $dnsaddr = $dnsaddrs[0]
} else {
    $dnsaddr = $dnsaddrs
}

if ($dnsaddr.Length -gt 0)
{
Set-PrivateProfileString "C:\Program Files\DHCPSrv\dhcpsrv.ini" GENERAL DNS_0 $dnsaddr
}
else
{
Set-PrivateProfileString "C:\Program Files\DHCPSrv\dhcpsrv.ini" GENERAL DNS_0 8.8.8.8
}


