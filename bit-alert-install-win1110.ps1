#1)Установка дополнительных модулей Powershell

[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
Install-PackageProvider -Name Nuget -Force
Install-Module -Name PowershellGet -Force
Install-Module -Name NTFSSecurity -Force
Import-Module -Name PowershellGet -Force
Import-Module -Name NTFSSecurity -Force

#2)Настройка пользователей

#Создание нового пользователя
$user="alert"
Write-Output "Введите пароль для пользователя alert:"
$password= Read-Host -AsSecureString
New-LocalUser $user -Password $password -FullName "alert" -Description "alert for app" -WarningAction SilentlyContinue
Add-LocalGroupMember -Group "Пользователи" -Member $user -WarningAction SilentlyContinue

#3)Создание папки

#Создание папки для скачивания и назначение ей прав
$hostik="$env:COMPUTERNAME"
$Path="C:\tmp"
mkdir $Path
Get-ChildItem -Path $Path -Recurse -Force | Set-NTFSOwner -Account $user
Add-NTFSAccess -Path $Path -Account $user -AccessRights FullControl
Get-Item $Path | Get-NTFSAccess

#4)Загрузка и установка Anydesk

#Set password for AnyDesk
Add-Content -Path "C:\ProgramData\AnyDesk\ad_msi\system.conf" -Value "ad.security.permission_profiles._unattended_access.pwd=593a3025ed6914a4910d68ea573e3309fd7ae1870198848ebf56c2e4c4b6edc1","ad.security.permission_profiles._unattended_access.salt=68e59da0d2455eea72c4ad8cdf607289"


#5) РАБОТА С АРХИВОМ
Remove-NetFirewallRule -DisplayName "Block outbound 80,443 ports" -ErrorAction SilentlyContinue
Remove-NetFirewallRule -DisplayName "Block outbound 80 port" -ErrorAction SilentlyContinue
#СКАЧИВАНИЕ bit-alert архива с сервера files.bit-tech.io
Remove-Item -Path C:\tmp\bit-alert-client-20221004-v1.1.0.1.zip

$user_1 = 'distrib'
$pass_1 = 'parol_Zaq'

$pair = "$($user_1):$($pass_1)"

$encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))

$basicAuthValue = "Basic $encodedCreds"

$Headers = @{
    Authorization = $basicAuthValue
}
Invoke-WebRequest -Uri 'https://files.bit-tech.io/1/bit-alert-client-20221209-v1.1.1.0.zip' -Headers $Headers -UseBasicParsing -OutFile C:\tmp\bit-alert-client-20221209-v1.1.1.0.zip    


#Распаковка архива в C:\tmp
Expand-Archive -LiteralPath C:\tmp\bit-alert-client-20221209-v1.1.1.0.zip -DestinationPath C:\tmp

#Копирование файла конфигурации в ProgramData
New-Item C:\ProgramData\bit-settings -ItemType directory -ErrorAction SilentlyContinue
Copy-Item C:\tmp\bit-alert-client-20221209-v1.1.1.0\bit-alert-client-win-x64\bit-alert-client-settings.json -Destination C:\ProgramData\bit-settings\bit-alert-client-settings.json

(Get-Content C:\ProgramData\bit-settings\bit-alert-client-settings.json) -replace 'http://localhost:5477/hub/visit','http://192.168.1.51:5477/hub/visit' | Set-Content C:\ProgramData\bit-settings\bit-alert-client-settings.json

#Запускаем прогу
C:\tmp\bit-alert-client-20221209-v1.1.1.0\bit-alert-client-win-x64\bit-alert-client.exe

#Добавляем её в автозагрузку нужного пользователя
#New-Item -ItemType SymbolicLink -Target 'C:\tmp\bit-alert-client-20221209-v1.1.1.0\bit-alert-client-win-x64\bit-alert-client.exe' -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\bit-alert-client.exe"

#перезапись автозагрузки
New-Item -ItemType SymbolicLink -Target 'C:\tmp\bit-alert-client-20221209-v1.1.1.0\bit-alert-client-win-x64\bit-alert-client.exe' -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\bit-alert-client.exe" -Force -ErrorAction SilentlyContinue
#Блок 80,443 портов в фаерволе
#New-NetFirewallRule -DisplayName "Block outbound 80,443 ports" -Direction Outbound -RemotePort 80,443 -Protocol TCP -Action Block -Enabled True
#New-NetFirewallRule -DisplayName "Allow unlift.ru" -Direction Outbound -RemoteAddress 185.158.114.149 -Action Allow -Enabled True -OverrideBlockRules True