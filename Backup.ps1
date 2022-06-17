Param (
    [string]$Path='./app',
    [string]$DestinationPath='./',
    [switch]$PathIsWebApp
)
    if ($PathIsWebApp -eq $true) {
        try {
            $ContainsApplicationFiles = "$((Get-ChildItem $Path).Extension | Sort-Object -Unique)" -match '\.js|\.html|\.css'
        
            if ( -Not $ContainsApplicationFiles) {
                Throw "Not a web app"
            }
            else {
                Write-Output "Source files loog good, continuing"
            }   
        }
        catch {
            Throw "No backup created due to: $($_.Exception.Message)"
        }

    }

if (-Not (Test-Path $Path))
{
    Throw "The source directory $Path does not exist, please specify an existing directory"
}

$date = Get-Date -format "yyyy-MM-dd"
$DestinationFile = "$($DestinationPath + 'backup-' + $date + '.zip')"
if (-Not (Test-Path $DestinationFile))
{
    Compress-Archive -Path $Path -CompressionLevel 'Fastest' -DestinationPath "$($DestinationPath + 'backup-' + $date)" -Force
    Write-Output "Created backup at $('./backup-' + $date + '.zip')"
}

else {
    Write-Error "Today's backup already exists"
}