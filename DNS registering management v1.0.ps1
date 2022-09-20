# Check Internet connectivity status
Function CheckInternetConnectivityStatus {

# First we create the request.
$HTTP_Request = [System.Net.WebRequest]::Create('http://download.windowsupdate.com')

# We then get a response from the site.
$HTTP_Response = $HTTP_Request.GetResponse()

# We then get the HTTP code as an integer.
$HTTP_Status = [int]$HTTP_Response.StatusCode

If ($HTTP_Status -eq 200) {
    Return "Connected"
}
Else {
    Return "NotConnected"
}

}


# Check connection location (Remote vs OnSite)
Function CheckConnectionLocation {
    $PingFRMA1149 = Test-Connection -ComputerName "FRMA1149.corp.internal" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
    $PingFRMA0838 = Test-Connection -ComputerName "FRMA0838.corp.internal" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

    If ($PingFRMA1149 -or $PingFRMA0838) { 
        $vpnconnection = Get-WmiObject -Class win32_networkadapter -computer localhost | Where-Object {$_.ServiceName -eq "PanGpd"}
        If ($vpnconnection.NetConnectionStatus -eq 2) { 
            Return "Remote"
        }
        Else {
            Return "OnSite"
        }
    }
    Else {
        Return "Remote"
    }

}

# Exit script if Internet connectivity is down
$InternetStatus = CheckInternetConnectivityStatus
If ($InternetStatus -eq "NotConnected") { Exit 0 }



$DeviceLocation = CheckConnectionLocation

# If device is running remotly = Disable "Register this connection’s address in DNS" parameter on wifi network card
If ($DeviceLocation -eq "Remote") {
    Get-NetAdapter -InterfaceDescription *Wi-Fi* | Set-DNSClient –RegisterThisConnectionsAddress $False
}


# If device is running at biomérieux site = Enable "Register this connection’s address in DNS" parameter on wifi network card
If ($DeviceLocation -eq "OnSite") {
    Get-NetAdapter -InterfaceDescription *Wi-Fi* | Set-DNSClient –RegisterThisConnectionsAddress $True
}

# Force DNS registration
Register-DnsClient -Verbose

