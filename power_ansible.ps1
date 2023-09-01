#SET UP controlling node to authenticate others host without being in the same domain

Set-Item WSMan:\localhost\Client\TrustedHosts -Value * -Force
Restart-Service WinRM

#Passing credentials (detect -detect-pwd) without prompt

#remote pc data
$remote_user="detect"
$remote_pass="detect-pwd"

#local_power_ansible_things
$path="C:\power_ansible"
$inventory="inventory.txt"

#auto-credentials
#$creds=Get-Credential
$securePassword = ConvertTo-SecureString "$remote_pass" -AsPlainText -Force
$credentials= New-Object System.Management.Automation.PSCredential ($remote_user,$securePassword)


$remote_hosts = @(
    "192.168.10.53",
    "192.168.10.95"
)

foreach ($remote_host in $remote_hosts) {
$session= New-PSSession -ComputerName $remote_host -Credential $credentials #-Authentication Credssp  #192.168.10.53

Invoke-Command -Session $session -ScriptBlock {
    #INPUT YOUR SCRIPT HERE
    
    #Get-Service -Name * | Where-Object {$_.Status -eq "Running"} | Select-Object -Property Name
    Get-Process -Name * | Where-Object {$_.CPU -gt 10} | Select-Object -Property Id,Name,CPU | Format-Table

}


}




#Create directory for inventory

#Remove-Item -Path $path -Recurse
#New-Item -Path $path -ItemType directory -WarningAction Ignore
#cd $path
#New-Item -Path $path\$invetory -WarningAction Ignore


#Set-Content -Path "$path\$inventory" -Value $null   #clear inventory before using
#notepad $inventory           #inventory to copy list of IP
#cat $inventory
