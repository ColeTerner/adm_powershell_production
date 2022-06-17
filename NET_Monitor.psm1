function Find-Network {
    [CmdletBinding(SupportsShouldProcess)]
    Param(
        [Parameter(Mandatory)]
        [int32]$NetNumber
        ,
        [Parameter(Mandatory)]
        [string]$Path
        ,
        [Parameter(Mandatory)]
        [int32]$start_of_range
        ,
        [Parameter(Mandatory)]
        [int32]$end_of_range
    )

    if ($start_of_range -gt $end_of_range) {
        Write-Output "Wrong range"
        break
    }
    #Determination of changing octets for network of class C
    $ip1=192
    $ip2=168
    $ip3=$NetNumber
    $ip4=$start_of_range

    for ($ip4=$start_of_range;$ip4 -le $end_of_range;$ip4++) {
        $IP="$ip1"+'.'+"$ip2"+'.'+"$ip3"+'.'+"$ip4"  #Pulling together the ip-address from octet-pieces
        Write-Output "Scanning host $ip1.$ip2.$ip3.$ip4" #Marking the current scanning host

        $attributes=@{                    #Creating hash-table(array) of attributes for each host
            IPAddress=$IP
            ComputerName=$null
            Status='OFFLINE'
            MAC=$null
            Processor=$null
            User=$null  #Added
            Password=$null #Added
        }
        #Connection's status
        if (Test-Connection -ComputerName $IP -Count 1 -Quiet) {
            $attributes.Status = 'ONLINE'
        }

        #DNS-name
        if ($DNS_Name = (Resolve-DnsName -Name $IP -ErrorAction SilentlyContinue).NameHost) {
            $attributes.ComputerName = $DNS_Name
            Set-Item WSMan:\localhost\Client\TrustedHosts -Value $DNS_Name -Force -ErrorAction SilentlyContinue #Adds a remote computer to list of trusted hosts(it's useful for sessions)
            #MAC-address
            $attributes.MAC=Get-CimInstance -Classname win32_Networkadapter -ComputerName $DNS_Name -ErrorAction SilentlyContinue | Where-Object {$_.AdapterType -eq "Ethernet 802.3"} | Where-Object {$_.MacAddress} | Select-Object -ExpandProperty macaddress

            #Processor's name
            $attributes.Processor=Get-CimInstance -Classname Win32_Processor -ComputerName $DNS_Name -ErrorAction SilentlyContinue | Select-Object -Property Name

            #User's name
            $attributes.User=Get-CimInstance -Classname win32_ComputerSystem   -ComputerName $DNS_Name -ErrorAction SilentlyContinue | Select-Object -Property Username  #Added later
        }
        else {
            $attributes.ComputerName = 'DOES NOT EXIST/diff OS'
        }

        [pscustomobject]$attributes | Export-Csv -Path $Path -Append -NoTypeInformation -Force        #Creating PSobject for each row of table and sending it into the outer CSV-file

    }
    $result=Import-Csv -Path $Path  #Imports the whole bunch of objects from the CSV-file to the array "$result"
    return $result  #Containing the whole table of objects
}


function New-HtmlReport {
    [CmdletBinding(SupportsShouldProcess)]
    Param (
        [Parameter(Mandatory,ValueFromPipelineByPropertyName=$true)]
        [string]
        $ComputerName
        ,
        [Parameter(Mandatory)]
        [string]$Path
    )
    process {
    Write-Output "Making report for $ComputerName ..."



    $File="$Path"+"\"+"$ComputerName"+".html"  #Creating the report's name from its path and name of computer

#Header of HTML report which includes css-styles within
    $Header="<style>
p {
	border: 2px double olive;
	background: DeepSkyBlue;
	padding: 15px;
    width:450px;
    text-align:center;
}

div {
	border:4px solid black;
	background: Blue;
    text-align:center;
    margin-top:10px;
}
table {
    border: 1px solid #000000;
    background: SkyBlue;
}
h1{
    background:MediumSlateBlue;
    text-align:center;
    display:inline-block;
    margin-left:50%;
    font-size:250%;
}
body {
    background:MediumAquamarine;
}
</style>"

    #WMI is the chosen technology for extraction info from local machines (distant Powershell sessions require more time for execution and demand additional settings with Powershell starting with 5.1)

    #Computer's Name
    $Name= "<b><h1>$ComputerName</h1></b><br>"

    #IPv4 IP-addresses of the remote machine
    $IP=Resolve-DnsName -Name $ComputerName | Where-Object {$_.Type -eq "A"} | Select-Object -Property "IPAddress" | ConvertTo-Html -PreContent "<b><big>IP-addresses</big></b>"


    #Cutting code for html-tags(div- for clauses , p - for subclauses)
    $p_start="<p><b><big>"
    $p_stop="</big></b></p>"

    $div_start="<div><b><h2>"
    $div_stop="</h2></b></div>"

                                                        #It's impossible to unite the first paragraph into the cycle because of the ability of conveyer - it's possible to change varibles into the left side of it

    #1.Info(first paragraph about OS and hardware of the remote computer)
    $Info= $div_start,"1.INFO",$div_stop

    #Fragment(Motherboard)
    $about_motherboard=Get-CimInstance -ComputerName $ComputerName -Classname win32_baseboard | Select-Object -Property Manufacturer,Product,Version,SerialNumber | ConvertTo-Html -PreContent $p_start,"1.1 Motherboard",$p_stop

    #Fragment(RAM)
    $about_ram=Get-CimInstance -ComputerName $ComputerName -Classname win32_physicalmemory | Select-Object -Property BankLabel,PartNumber,@{Label="Capacity(Gb)"; Expression={$_.Capacity/1Gb}},ConfiguredClockSpeed,ConfiguredVoltage,SerialNumber | ConvertTo-Html -PreContent $p_start,"1.2 RAM",$p_stop

    #Fragment(Processor)
    $about_processor=Get-CimInstance -ComputerName $ComputerName -Classname win32_processor |Select-Object -Property Name,ThreadCount,Virualization,AddressWidth,MaxClockSpeed | ConvertTo-Html -PreContent $p_start,"1.3 Processor",$p_stop

    #Fragment(Physical disks)
    $about_physicaldisks=Get-CimInstance -ComputerName $ComputerName -Classname win32_diskdrive | Select-Object -Property DeviceID,Caption,Status,InterfaceType,@{Label="Size(Gb)"; Expression={[math]::Round($_.Size/1Gb,1)}},SerialNumber | ConvertTo-Html -PreContent $p_start,"1.4 Physical disks",$p_stop

    #Fragment(network adapter with type of Ethernet)
    $about_netAdapter=Get-CimInstance -ComputerName $ComputerName -Classname win32_NetworkAdapter |Where-Object {$_.NetConnectionID -eq "Ethernet"} |Select-Object -Property Name,Description,MACAddress,PhysicalAdapter | ConvertTo-Html -PreContent $p_start,"1.5 Network adapter ETHERNET",$p_stop


    #Fragment(Operating system)
    $about_operatingSystem=Get-CimInstance -ComputerName $ComputerName -Classname win32_operatingsystem | Select-Object -Property Name,OSArchitecture,Version,SerialNumber,SystemDirectory | ConvertTo-Html -PreContent $p_start,"1.6 Operating system",$p_stop

    #Fragment(BIOS)
    $about_bios=Get-CimInstance -ComputerName $ComputerName -Classname win32_bios | Select-Object -Property Description,Manufacturer,Status,PrimaryBIOS,ReleaseDate | ConvertTo-Html -PreContent $p_start,"1.7 BIOS",$p_stop

    #Fragment(Videocard)
    $about_graphics=Get-CimInstance -ComputerName $ComputerName -Classname Win32_VideoController | Select-Object -Property DeviceID,VideoProcessor,CurrentHorizontalResolution,CurrentVerticalResolution | ConvertTo-Html -PreContent $p_start,"1.8 Videocard",$p_stop


    #2.Perfomance(second paragraph about state of system in the real time)
    $Perfomance= $div_start,"2.PERFOMANCE",$div_stop

    #Fragment(Logical disks of OS)
    $about_logicaldisks=Get-CimInstance -ComputerName $ComputerName -Classname win32_logicaldisk | Select-Object -Property DeviceID,VolumeName,FileSystem,@{Label="FreeSpace(Gb)"; Expression={[math]::Round($_.FreeSpace/1Gb,1)}},@{Label="Size(Gb)"; Expression={[math]::Round($_.Size/1Gb,1)}} | ConvertTo-Html -PreContent $p_start,"2.1 Logical partitions of OS ",$p_stop

    #Fragment(Available RAM , in %) #-Counter '\Memory\Available MBytes'(for eng version of OS Windows)
    $about_ramusage=Get-Counter -ComputerName $ComputerName -Counter '\Memory\Available MBytes' -ErrorAction SilentlyContinue | Select-Object -Property TimeStamp,Readings | ConvertTo-Html -PreContent $p_start,"2.2 Free RAM in % (at the current moment)",$p_stop

    #Fragment(Percent usage of processor) #-Counter '\Processor(_Total)\% Processor Time'(for eng version of OS Windows)
    $about_cpuUsage=Get-Counter -ComputerName $ComputerName -Counter '\Processor(_Total)\% Processor Time' -ErrorAction SilentlyContinue | Select-Object -Property TimeStamp,Readings | ConvertTo-Html -PreContent $p_start,"2.3 CPU usage in %(at the current moment)",$p_stop

    #Fragment(Working services of OS)
    $about_services=Get-Service -ComputerName $ComputerName | Where-Object {$_.Status -eq "Running"} | Select-Object -Property Name,Status | ConvertTo-Html -PreContent $p_start,"2.4 Services(Running)",$p_stop

    #Fragment(Processes of OS with usage of CPU >=10)
    try {
        $about_processes=Get-Process -ComputerName $ComputerName -ErrorAction SilentlyContinue | Where-Object {$_.CPU -ge 10} | Select-Object -Property Id,ProcessName,CPU | ConvertTo-Html -PreContent $p_start,"2.5 Processes",$p_stop
    }
    catch {
        Write-Output "Inforamtion about the processes at the remote host can't be extracted.Check status of the service 'RemoteRegistry' and open 135 TCP port at the remote computer..."
    }
    #3.Printers(third paragraph about outer printers)
    $Printers=$div_start,"3.AVAILABLE PRINTERS",$div_stop

    #Fragment(Available printers on the remote machine)
    $about_printers=Get-CimInstance -ComputerName $ComputerName -classname win32_printer | Select-Object -Property DeviceID,Default,Network,HorizontalResolution,VerticalResolution | ConvertTo-Html -PreContent $p_start,"3.1 Connected printers",$p_stop


    ConvertTo-Html -Head $Header -Body "$Name $IP $Info $about_motherboard $about_ram $about_processor $about_physicaldisks $about_netAdapter $about_operatingSystem $about_bios $about_graphics $Perfomance $about_logicaldisks $about_ramusage $about_cpuUsage $about_services $about_processes $Printers $about_printers" -Title "$ComputerName  report" | Out-File $File  #Gathering the blocks of HTML-code into the single outer file with name of PC and path from input
    }
}



function Watch-TcpConnection {
    [CmdletBinding(SupportsShouldProcess)]
    Param (
        [Parameter(Mandatory,ValueFromPipelineByPropertyName=$true)]
        [string]$ComputerName
        ,
        [Parameter(Mandatory)]
        [int32[]] $tcp_ports
        ,
        [Parameter(Mandatory=$true)]
        [string]$token
        ,
        [Parameter(Mandatory=$true)]
        [string]$chatID
        ,
        [Parameter(Mandatory=$true)]
        [string]$LogPath

    )
    process {
    #Creating new PS-session with the remote computer
    $session=New-PSSession -ComputerName $ComputerName -Name CheckTCPPorts -ErrorAction SilentlyContinue


    #Checking the connection
        #(In the case of "yes" - each port from input is going to be checked againt the table of established connections which was acquired from the remote server,
        #if the numbers of those two ports matches then the program sends notification to system administrator. Otherwise , it writes about what it's impossible to create remote session

    $zero=$null
    If ($session -ne $zero ) {
        Write-Output "The connection had been succesfully established"
    #Executing an infinite cycle(just like a service in operating system)


        while ($true) {

         $IncomingConnection =Invoke-Command -session $session -scriptblock { Get-NetTCPConnection -State Established }


        foreach ($port in $tcp_ports) {  #The cycle through input ports
            foreach ($connection in $IncomingConnection) { #The incapsulated cycle through active TCP-connections at the remote server

                if ($connection.LocalPort -eq $port) {
                    Write-Output "Established connection was detected on $port port!"
                    "ALERT!!! SOMEONE IS TRYING TO REACH YOUR SERVER $ComputerName BY USING $port PORT! " | New-TelegramMessage -token $token -chatID $chatID -ErrorAction SilentlyContinue

                    #Writing logs (date + message)
                    $date=Get-Date -Format "HH:mm dd-MM-yyyy"
                    $date+"   "+"ALERT!!! SOMEONE IS TRYING TO REACH YOUR SERVER $ComputerName BY USING $port PORT! " | Out-File -FilePath $LogPath -Append
                }

            }

        }
        Start-Sleep 60
       }



    }
    else {
        Write-Output "Impossible to create session. Check the status of WMI service at the distant computer"
    }

    }
}



function Watch-DiskCSpace {
    [CmdletBinding(SupportsShouldProcess)]  #For supporting such attributes like -whatif and -confirm
    Param (
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName)]
        [string]$ComputerName
        ,
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName)]
        [string]$token
        ,
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName)]
        [string]$chatID
    )
process {
$session=New-PSSession -ComputerName $ComputerName -Name CheckDiskC  #Session's name serves as identificator for farther her eliminating

#Invoke-Command -Session $session -ArgumentList $token,$chatID -ScriptBlock {

    while ($true) {
        $HostName=Invoke-Command -Session $session -ScriptBlock {hostname}
        $FreeSpace=(Get-CimInstance -ComputerName $ComputerName -ClassName  win32_logicaldisk | Where-Object {$_.Name -eq "C:"}).FreeSpace
        $FullSize=(Get-CimInstance -ComputerName $ComputerName -ClassName  win32_logicaldisk | Where-Object {$_.Name -eq "C:"}).Size
        $FreeSpaceInPercents=[math]::Round(($FreeSpace/$FullSize)*100,1)  #Calculating free disk space in % and rounding the number to a single symbol after comma

        if ($FreeSpaceInPercents -lt 20) {        #If the number is lower than 20
            $message="ALERT!!! FREE DISK C SPACE IS EQUAL $FreeSpaceInPercents PERCENTS AT HOST $HostName ! Take some actions!"
            Write-Output $message
            $message | New-TelegramMessage -token $token -chatID $chatID -ErrorAction SilentlyContinue #Sending message to the Telegram chat

            #Deleting temporary files in "C:\Windows\Temp" folder (if that's impossible the exception is invoked)
        Invoke-Command -Session $session -ScriptBlock {
            $temp_files=Get-ChildItem -Path C:\Windows\Temp -Recurse -Force

            foreach ($temp_file in $temp_files) {
                try {
                    #$_.Delete() - can't delete most of files because of that what operating system locked them
                    Remove-Item $temp_file -ErrorAction SilentlyContinue
                    Write-Output "File $temp_file was succesfully deleted!"
                }
                catch {
                    Write-Output "File $temp_file is been using by operating system. It's impossilbe to delete!"
                }
            }
            }
        }

        Start-Sleep 120
    }
#}
}
}



function New-TelegramMessage {
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact='Medium')]
    Param (
        [Parameter(Mandatory=$true)]
        [string]$token
        ,
        [Parameter(Mandatory=$true)]
        [string]$chatID
        ,
        [Parameter(Mandatory=$true,ValueFromPipeline)]
        [string]$message
        ,
        [Parameter()]
        [string]$email_from
        ,
        [Parameter()]
        [string]$email_to
        ,
        [Parameter()]
        [string]$SmtpServer
        ,
        [Parameter()]
        [string]$subject

    )
process {

    #1. Support of e-mail(check of input if it required)
    if (($email_from -ne $null) -and ($email_to -ne $null) -and ($SmtpServer -ne $null) -and ($subject -ne $null)) {
        Send-MailMessage -Body $message -From $email_from -To $email_to -SmtpServer $SmtpServer -Subject $subject
    }
    else {
        Write-Output "Some of the parameters of e-mail weren't set!"
    }
#Confirmation
if ($PSCmdlet.ShouldProcess("ShouldProcess?")) {
        Write-Output "Just warning! Some of the mail parameters might not be set in place - email_from,email_to,SmtpServer,subject"
    }

    #2.Sending of messages to the Telegram

    $URL="https://api.telegram.org/bot"+$token+"/sendMessage?chat_id="+$chatID+"&text="+$message  #Creating the URL with the text of alert for bot account

    $URL_request= Invoke-WebRequest -Uri $URL          #Sending the alert by using URL-request with generated URL
    Write-Output $URL_request
}
}



function Set-CommfortRemoteDesktop {
    [CmdletBinding(SupportsShouldProcess)]
    Param (
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName)]
        [string]$ComputerName
        ,
        [Parameter(Mandatory=$true)]
        [String]$Password
        ,
        [Parameter(Mandatory=$true)]
        [String]$Username
    )

Invoke-Command -ComputerName $ComputerName -ScriptBlock {
    #Creating the path to the config of Commfort programm - main.ini -withing user path C:\Users\<username>
    $ComfortPath="C:\Users\$using:Username\AppData\Roaming\CommFort\Default\Config\Main.ini"

    #Invoking the "replace" method for changing of all values of attributes within the desktop paragraph. After that the document is directed to change its content
    (Get-Content $ComfortPath) -replace '^AccessMode=1$','AccessMode=2' -replace '^PasswordAccessMode=0$', "PasswordAccessMode=1" -replace "^Password=$", "Password=$using:Password" | Set-Content  $ComfortPath

    #Checking done changes
    if ( ((Get-Content $ComfortPath) -ccontains 'AccessMode=2') -and ((Get-Content $ComfortPath) -ccontains 'PasswordAccessMode=1') -and ((Get-Content $ComfortPath) -ccontains "Password=$args")) {
        Write-Output "Config file of Commfort was succesfully changed!"
    }
}

}




