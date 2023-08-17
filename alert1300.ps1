#1)Create folder for alert1300
New-Item C:\alert1300 -ItemType directory -ErrorAction SilentlyContinue

#2)Download the archive from file server

$user_1 = 'distrib'
$pass_1 = 'parol_Zaq'

$pair = "$($user_1):$($pass_1)"

$encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))

$basicAuthValue = "Basic $encodedCreds"

$Headers = @{
    Authorization = $basicAuthValue
}

#CHANGE THE NAME OF DOWNLOADED ARCHIVE
Invoke-WebRequest -Uri 'https://files.bit-tech.io/1/bit-alert-client-win-x64-v1.3.0.0.zip' -Headers $Headers -UseBasicParsing -OutFile C:\alert1300\bit-alert-client-win-x64-v1.3.0.0.zip 

#3)Expand the archive with alert 1300

Expand-Archive -LiteralPath C:\alert1300\bit-alert-client-win-x64-v1.3.0.0.zip -DestinationPath C:\alert1300

#4)Copy and edit config json file from C:\tmp\alert1300\ to C:\ProgramData\bit-settings\bit-alert-client-settings.json

Copy-Item C:\alert1300\bit-alert-client-win-x64-v1.3.0.0\win-x64\bit-alert-client-settings.json -Destination C:\ProgramData\bit-settings\bit-alert-client-settings.json

(Get-Content C:\ProgramData\bit-settings\bit-alert-client-settings.json) -replace 'http://localhost:5477/hub/visit','http://192.168.1.51:5477/hub/visit' | Set-Content C:\ProgramData\bit-settings\bit-alert-client-settings.json

#5)Launch new bit-alert

C:\alert1300\bit-alert-client-win-x64-v1.3.0.0\win-x64\bit-alert-client.exe



#6)Remove old alert from autolaunch and add the new one by using symlink
Remove-Item -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\bit-alert-client.exe"
New-Item -ItemType SymbolicLink -Target 'C:\alert1300\bit-alert-client-win-x64-v1.3.0.0\win-x64\bit-alert-client.exe' -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\bit-alert-client.exe" -Force -ErrorAction SilentlyContinue
   

