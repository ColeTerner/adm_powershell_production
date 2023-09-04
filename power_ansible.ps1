#1.REQUIREMENTS

#(!!!) CONTROL HOST DEMANDS
#SET UP controlling node to authenticate others host without being in the same domain
#Set-ExecutionPolicy -ExecutionPolicy RemoteSigned
#Enable-PSRemoting

Set-Item WSMan:\localhost\Client\TrustedHosts -Value * -Force
Restart-Service WinRM
Set-Service WinRM -StartupType Automatic

#(!!!) ON THE REMOTE HOSTS requirments:
#-Set-ExecutionPolicy -ExecutionPolicy RemoteSigned
#-Enable-PSRemoting
#-WinRm running and enabled
#-USER EXISTENCE WITH DOWNBELOW CREDENTIALS

#2.INVENTORY (REMOTE HOST DATA)
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


#3.INVENTORY (REMOTE HOSTS IPs or Domain-names)
$remote_hosts = @(
    "192.168.10.53",
    "192.168.10.95"
)


#4.REMOTE PSSession for each remote host
foreach ($remote_host in $remote_hosts) {
$session= New-PSSession -ComputerName $remote_host -Credential $credentials #-Authentication Credssp  #192.168.10.53

Invoke-Command -Session $session -ScriptBlock {
    #INPUT YOUR SCRIPT HERE
    
    #Get-Service -Name * | Where-Object {$_.Status -eq "Running"} | Select-Object -Property Name
    #Get-Process -Name * | Where-Object {$_.CPU -gt 10} | Select-Object -Property Id,Name,CPU | Format-Table
    New-Item -Path C:\dekstro.txt -Force
    Set-Content -Value "try me" -Path C:\dekstro.txt

}


}




