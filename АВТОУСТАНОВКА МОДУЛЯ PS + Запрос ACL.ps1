Get-Acl -Path F:\Диплом  #Запрос ACL листа прав безопасности

$env:PSModulePath  #где хранятся модули

#ПРОВЕРКА НАЛИЧИЯ МОДУЛЯ И ЕГО АВТОУСТАНОВКА

<#
$Path="C:\Program Files\WindowsPowerShell\Modules\SNMP"
if (Test-Path $Path)
    {Write-Output "okay..."}
else {
    Install-Module -Name SNMP -Force
    Update-Module -Name SNMP -Force #автоапдейт до ласт версии
}
#>

<#
foreach ($p in $env:PSModulePath) {
    Test-Path ($p +"\SNMP")
}
#>

# САМОЕ ПРОСТОЕ И РАБОЧЕЕ РЕШЕНИЕ (!!!)
if (Get-Module -Name SNMP -ListAvailable)
    {Write-Output "It's already there!"}
else
    {Install-Module -Name SNMP -Force}   #при скачивании итак ласт версия
    