function New-Backup {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true,ValueFromPipeline,HelpMessage="Введите путь к каталогу , КОТОРЫЙ нужно архивировать",Position=2)]
        [string]$Path
        ,
        [Parameter(Mandatory=$true,HelpMessage="Введите путь к каталогу , в который будет СОХРАНЕН бекап")]
        [string]$DestinationPath
    )

#Проверка пути If (-Not (Test-Path $DestinationFile)) - можно выполнить проверку на существование имеющегося бекапа по этому пути , либо использовать атрибут -Force у Compress-Archive для перезаписи
if (Test-Path -Path $Path) {
    $date=Get-Date -Format "yyyy-MM-dd"
    Compress-Archive -Path $Path -CompressionLevel "Fastest" -DestinationPath "$($DestinationPath + '\backup-' + $date)" -Force 
    Write-Output "Created backup at $($DestinationPath + "\backup-" + $date + '.zip')"
}
else {
    Write-Output "НЕВЕРНО УКАЗАН ЗАДАННЫЙ ПУТЬ В АТРИБУТЕ `$Path"
}

}

New-Backup -Path 'F:\d2' -DestinationPath 'F:\9 ярус'
