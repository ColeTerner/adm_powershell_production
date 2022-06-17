#Here is you need to update your module PowershellGet (with package provider)
Import-PackageProvider -Name Nuget
Install-Module -Name PowershellGet -Force

#Repo - Chocolatey, put it in TRUSTED
Get-PackageProvider -Name Chocolatey -ForceBootstrap
Set-PackageSource -Name Chocolatey -Trusted

#Install module Chocolatey
Install-Module -Name Chocolatey -Force
Import-Module -Name Chocolatey
Get-Module | Format-Table

#For using the utility inside the CMD
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

#Commands for the utility Chocolatey
    #cinst название_пакета — установка приложения
    #cuninst название_пакета — удаление приложения
    #cup название_пакета — обновление приложения
    #cup all — обновление всех установленных приложений
    #clist название_пакета — поиск приложений

cinst opera --force -y
cinst kis --force -y   # Autoinstallation of kaspersky !!!
cinst thunderbird --force -y   #Thunderbird installation

cuninst thunderbird --force -y #DELETION of package Thunderbird(95% working, with Opera - NOT WORKING)