function Check-Time {
	$h = [int](Get-Date -Format "HH")

	if ($h -ge 17 -and $h -le 18) { 
	.\deltoken.bat
	exit
	}
	
	else {
	cls
	Write-Host "It is not currently within the timeframe. Restarting script..."
	Timeout /t 15
	Check-Time
	}
}

Check-Time

