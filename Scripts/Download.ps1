# 
# This PowerShell script make a file download and setup all variables for work with Automic
# version
# Make the Job in N steps
# Step 1 Download
# Step 2 Expand Files
# Step 3 Change the Name of Agents
# Step 4 Install
# Step 5 Start Services all



Param(
    [string]$organization= "releasea",
    [string]$projectName = "AprovisionamientoAutomatico",
    [string]$repoId= "ArtefactosAprovisionamiento",
    [string]$appPath= "Binarios/Automic.zip",
    [string]$user = "",
    [string]$token = "uvay7nxx5zq3mgktj66lnlsmr5ouhins3n5z43pekg26judfzyca",
    [string]$outPath = [System.Environment]::GetEnvironmentVariable('TEMP','Machine'),
    [string]$agentName = "$(Get-Content env:computername)",
    [string]$installPath = "C:\"
 
 
 )

 Function LogWrite
 {  
    Param ([string]$logstring)
    $Logfile = "$env:temp\$(Get-Content env:computername).log" 
    $date = Get-Date -Format "MM/dd/yyyy HH:mm:ss"
    Add-content $Logfile -value "$date    $logstring"
 }
 

 
 #Step 1
     LogWrite "Iniciando Descarga de Binarios"
     #"Iniciando Descarga de Binarios" | Out-File C:\Users\walter.bermudez\log.log -Append
     $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $user,$token)))
     $uri = "https://dev.azure.com/$($organization)/$($projectName)/_apis/git/repositories/$($repoId)/items?scopePath=$($appPath)&format=zip&api-version=5.0"
     $outPath = Join-Path -Path $outPath -ChildPath $appPath.Split("/")[-1]
 
         Try{
             Invoke-RestMethod -Uri $uri -Method Get -ContentType "application/zip" -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -OutFile $outPath
             #"Descarga Exitosa" | Out-File C:\Users\walter.bermudez\log.log -Append
             LogWrite "Descarga Exitosa" 
         }
         Catch{
             #"Fallo en la descarga " + $_.Exception | Out-File C:\Users\walter.bermudez\log.log -Append
             LogWrite "Fallo en la descarga:  $_.Exception "
             Break
         }
 
 #Step 2
   
             LogWrite "Descomprimiento los binarios en $installPath"
         Try{
             #Expand-Archive -Path $outPath -DestinationPath $installPath -Force
             [System.Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem')
             [System.IO.Compression.ZipFile]::ExtractToDirectory($outPath, $installPath)
             LogWrite "Descompresion exitosa en $installPath"
         }
         Catch{
             LogWrite "Fallo al descomprimir:   $_.Exception "
             Break
         }
 #Step 3
 #TO DO Recursive or defined?

 ((Get-Content -path "$($installPath)Automic\Agents\windows\bin\UCXJWX6.ini" -Raw) -replace 'CLAROAGENT',$agentName) | Set-Content -Path "$($installPath)Automic\Agents\windows\bin\UCXJWX6.ini"
 ((Get-Content -path "$($installPath)Automic\ServiceManager\bin\uc4.smc" -Raw) -replace 'CLAROAGENT',$agentName) | Set-Content -Path "$($installPath)Automic\ServiceManager\bin\uc4.smc"
 ((Get-Content -path "$($installPath)Automic\ServiceManager\bin\UC4.smd" -Raw) -replace 'CLAROAGENT',$agentName) | Set-Content -Path "$($installPath)Automic\ServiceManager\bin\UC4.smd"
 ((Get-Content -path "$($installPath)Automic\Agents\windows\bin\UCXJWX6.kstr" -Raw) -replace 'CLAROAGENT',$agentName) | Set-Content -Path "$($installPath)Automic\Agents\windows\bin\UCXJWX6.kstr"
 

 #Step 4
     LogWrite "Configurando CAPKI ........."
     & "$($installPath)Automic\CAPKI\x64\setup.exe" install caller=AE122 verbose env=all 
 
     LogWrite "Configurando SM"
     & "$($installPath)Automic\ServiceManager\bin\UCYBSMgr.exe" -install UC4
 
     Start-Service -Name "UC4.ServiceManager.UC4" 