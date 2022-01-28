$wipeConfigImport = Get-Content -Path E:\rusttest\wipeconfig.json
$vPSObject = $wipeConfigImport | ConvertFrom-Json
$rustServerDir = $vPSObject[0].rustServerDirectory
$wipeToken = Join-Path -Path $rustServerDir -Childpath wipetoken.json
$latest = Join-Path -Path $rustServerDir -Childpath latest.json
$installed = Join-Path -Path $rustServerDir -Childpath installed.json
$rustLog = Join-Path -Path $rustServerDir -Childpath wipe.log
$rustOxide = Join-Path -Path $rustServerDir -Childpath Oxide.Rust.zip
$serverCFGDir = $vPSObject[0].serverCFGDirectory
$serverCFG = Join-Path -Path $serverCFGDir -Childpath server.cfg
$serverSeedList = Join-Path -Path $serverCFGDir -Childpath seedlist.txt
$serverSeedListTemp = Join-Path -Path $serverCFGDir -Childpath seedlist_temp.txt
$saveMapDir = $vPSObject[0].saveAndMapDirectory
$steamCMDPath = $vPSObject[0].steamCMDPath
$rustServiceName = $vPSObject[0].rustServiceName
$checkUpdateFreq = $vPSObject[0].checkForUpdateFrequency
$uMod = 'https://umod.org/games/rust/latest.json'

function Start-RustLog {
    try {
        Start-Transcript -Path $rustLog
    }
    catch {
        throw $_.Exception.Message
        Stop-Transcript
    }
}

function Stop-RustLog {
    try {
        Stop-Transcript
    }
    catch {
        throw $_.Exception.Message
        Stop-Transcript
    }
}


function Confirm-RustUpdate {
    
    Write-Host "Downloading latest Version Information..."
    Invoke-WebRequest -URI $uMod -O $latest

    $latestCompare = Get-Content $latest | ConvertFrom-Json
    $installedCompare = Get-Content $installed | ConvertFrom-Json

    if ($latestCompare.version -eq $installedCompare.version) {
        Write-Host "No Update Required"
        Timeout /t $checkUpdateFreq
        Confirm-RustUpdate
    }
    elseif ($latestCompare.version -ne $installedCompare.version) {
        Write-Host "A new update is available. Starting Update..."
        
        New-Item -Path $rustServerDir -Name 'installed_temp.json'
        $installedTemp = $rustServerDir + 'installed_temp.json'
        Get-Content $latest | Set-Content $installedTemp
        Move $installedTemp $installed -Force

    }
    else {
       throw $_.Exception.Message
       Stop-Transcript
    }
}

function Create-WipeToken {
    New-Item $wipeToken -Force
}

function Check-WipeToken {
    if (Test-Path -Path $wipeToken -PathType Leaf) {
        try {
            Write-Host "The wipetoken already exists. Exiting script."
            Stop-Transcript
            Exit
        }
        catch {
            throw $_.Exception.Message
            Stop-Transcript
        }
    }
    else {
        Write-Host "The wipetoken does not exist. Continuing script."
    }

}

function Check-Installed {
    if (Test-Path -Path $installed -PathType Leaf) {
        try {
            Write-Host "installed.json exists, continuing script."    
        }
        catch {
            throw $_.Exception.Message
            Stop-Transcript
        }
    }
    else {
        try {
            New-Item $installed
            Write-Host "installed.json did not exist, created empty installed.json"
            Invoke-WebRequest -URI $uMod -O $installed
            Write-Host "Populated installed.json with latest oxide version information."
        }
        catch {
            throw $_.Exception.Message
            Stop-Transcript
        }
    }
}

function Initialize-Wipe {
    Write-Host "Starting Update..."
    
    try {
        Write-Host "Shutting down the server."
        Stop-Service -Name $rustServiceName
        Timeout /t 10

        $cmd = $steamCMDPath
        $prm = '+force_install_dir $rustServerDir', '+login anonymous', '+app_update 258550 validate', '+quit'

        & $cmd $prm

        Invoke-WebRequest -URI https://umod.org/games/rust/download -O $rustOxide
    
        Expand-Archive -Path $rustOxide -DestinationPath $rustServerDir -Force

        Remove-Item $rustOxide

        Write-Host "Rust and Oxide have been updated..."

        Timeout /t 5
    }
    catch {
        throw $_.Exception.Message
        Stop-Transcript
    }
}

function Start-RustServer {
    try {
        Start-Service -Name $rustServiceName
    }
    catch {
        throw $_.Exception.Message
        Stop-Transcript
    }
}

function Wipe-RustFiles {
    
    Join-Path -Path $rustServerDir -ChildPath oxide\logs\*.txt | Remove-Item
    Write-Host "Oxide Log files removed."

    Join-Path -Path $saveMapDir -ChildPath *.sav* | Remove-Item
    Join-Path -Path $saveMapDir -ChildPath *.txt | Remove-Item
    Join-Path -Path $saveMapDir -ChildPath *.db* | Remove-Item
    Join-Path -Path $saveMapDir -ChildPath *.map | Remove-Item
    Join-Path -Path $saveMapDir -ChildPath *.id | Remove-Item
    Write-Host "Rust map, database, save, text, and id files deleted."
}

function Update-Seedlist {
    $servCFG = Get-Content $serverCFG
    
    try {
        $line = Get-Content $serverCFG  | Select-String "server.seed" | Select-Object -ExpandProperty Line
        $replaceLine = Get-Content $serverSeedList -First 1
    
        $servCFG | ForEach-Object {$_ -replace $line, $replaceLine} | Set-Content $serverCFG

        Get-Content $serverSeedList | Select -skip 1 | Set-Content $serverSeedListTemp
        Move $serverSeedListTemp $serverSeedList -Force
    }
    catch {
        throw $_.Exception.Message
        Stop-Transcript
    }
}

Start-RustLog
Check-WipeToken
Check-Installed
Confirm-RustUpdate
Update-Seedlist
Initialize-Wipe
Wipe-RustFiles
Start-RustServer
Create-WipeToken
Stop-RustLog
Write-Host -NoNewLine 'The script has finished. Press any key to exit.'
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
Exit