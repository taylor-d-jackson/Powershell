function factGenerator {
    param(
    [string]$intro = "Prepare for a random fact...",
    [int]$random = (Get-Random -Maximum 1400),
    [string]$fact= (((Invoke-WebRequest -Uri http://www.randomfactgenerator.net?id=$random).links)."data-text"),
    [int]$speechRate= 1

    )
        $factSpeech = "$intro $fact"
        $voiceObject = New-Object -com SAPI.SpVoice
        $voice = $voiceObject.getVoices()|where {$_.id -like "*DAVID*"}
        $voiceObject.voice = $voice
        $voiceObject.rate = $speechRate
        $voiceObject.speak($factSpeech)
}
factGenerator