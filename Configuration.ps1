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
    [string]$jdkPath= "Binarios/jdk-8u144-windows-x64.zip",
    [string]$user = "",
    [string]$token = "uvay7nxx5zq3mgktj66lnlsmr5ouhins3n5z43pekg26judfzyca",
    [string]$outPath = [System.Environment]::GetEnvironmentVariable('TEMP','Machine'),
    [string]$agentName = "$(Get-Content env:computername)",
    [string]$installPath = "C:\",
    [string]$software = "Java SE Development Kit 8 Update 144 (64-bit)"
 
 
 )

 Function LogWrite
 {  
    Param ([string]$logstring)
    $Logfile = "$env:temp\$(Get-Content env:computername).log" 
    $date = Get-Date -Format "MM/dd/yyyy HH:mm:ss"
    Add-content $Logfile -value "$date    $logstring"
 }
 
 #Step 0
 
 
 if ( (Get-WMIObject win32_operatingsystem).name -like "*2008*" )
 {
 LogWrite "Windows 2008 is Detected"
 foreach ($disk in get-wmiobject Win32_DiskDrive -Filter "Partitions = 0")
    { 
   $disk.DeviceID
   $disk.Index
   "select disk "+$disk.Index+"`r clean`r create partition primary`r format fs=ntfs unit=65536 quick`r active`r assign letter=F" | diskpart
    }
}
else
 {
 LogWrite "Windows 2012 is Detected"
 $disks = Get-Disk | Where-Object partitionstyle -eq 'raw' | Sort-Object number

 $letters = 70..89 | ForEach-Object { [char]$_ }
 $count = 0
 $labels = "data1","data2"

 foreach ($disk in $disks) {
     $driveLetter = $letters[$count].ToString()
     $disk | 
     Initialize-Disk -PartitionStyle MBR -PassThru |
     New-Partition -UseMaximumSize -DriveLetter $driveLetter |
     Format-Volume -FileSystem NTFS -NewFileSystemLabel $labels[$count] -Confirm:$false -Force
 $count++
 }
}
 #end Step 0

 #Step 0.1
    LogWrite "Iniciando Descarga de Jdk"
    #"Iniciando Descarga de Binarios" | Out-File C:\Users\walter.bermudez\log.log -Append
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $user,$token)))
    $uri = "https://dev.azure.com/$($organization)/$($projectName)/_apis/git/repositories/$($repoId)/items?scopePath=$($jdkPath)&format=zip&api-version=5.0"
    $outPathJdk = Join-Path -Path $outPath -ChildPath $jdkPath.Split("/")[-1]
  

     Try{
         #Invoke-RestMethod -Uri $uri -Method Get -ContentType "application/zip" -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -OutFile $outPathJdk
         Invoke-WebRequest -Uri https://dl.dropbox.com/s/z5r5kzlf1agawn1/jdk-8u144-windows-x64.zip?dl=1 -OutFile $outPathJdk
         #"Descarga Exitosa" | Out-File C:\Users\walter.bermudez\log.log -Append
         LogWrite "Descarga Exitosa de Jdk" 
     }
     Catch{
         #"Fallo en la descarga " + $_.Exception | Out-File C:\Users\walter.bermudez\log.log -Append
         LogWrite "Fallo en la descarga de Jdk:  $_.Exception "
         Break
     }

  
  LogWrite $outPathJdk
  LogWrite $outPath
  
     LogWrite "Descomprimiento el JDK en $outPath"
     Try{
         #Expand-Archive -Path $outPath -DestinationPath $installPath -Force
         [System.Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem')
         [System.IO.Compression.ZipFile]::ExtractToDirectory($outPathJdk, $outPath)
         LogWrite "Descompresion exitosa en $outPath"
     }
     Catch{
         LogWrite "Fallo al descomprimir JDK:   $_.Exception "
         Break
     }

 #Install JDK Silenty
  & "$($outPath)\jdk-8u144-windows-x64.exe" /s ADDLOCAL="ToolsFeature,SourceFeature,PublicjreFeature" INSTALLDIR=C:\progra~1\Java\x64\jdk1.8.1_44 /INSTALLDIRPUBJRE=C:\progra~1\Java\x64\jre1.8.1_44
 #Wait for JDK instalation
 LogWrite "Waiting 120 Seconds for continue"
 Start-Sleep -s 120 
 #Check if JDK was installed


$installed = (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.DisplayName -eq $software }) -ne $null

If(-Not $installed) {
    #Write-Host "'$software' NOT is installed.";
    LogWrite "'$software' NOT is installed"
} else {
    LogWrite  "'$software' is installed."
    $envPath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $envPath += ";C:\progra~1\Java\x64\jdk1.8.1_44\bin"  
    LogWrite = "Setting env ..."
    [Environment]::SetEnvironmentVariable('Path', $envPath, 'Machine')        
    
    $envJavaHome += "C:\progra~1\Java\x64\jdk1.8.1_44"  
    LogWrite = "Setting env Java Home..."
    [Environment]::SetEnvironmentVariable('JAVA_HOME', $envJavaHome, 'Machine')    
   
   
}



 #END STEP 0.1

  #Step 1
     LogWrite "Iniciando Descarga de Binarios"
     #"Iniciando Descarga de Binarios" | Out-File C:\Users\walter.bermudez\log.log -Append
     $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $user,$token)))
     $uri = "https://dev.azure.com/$($organization)/$($projectName)/_apis/git/repositories/$($repoId)/items?scopePath=$($appPath)&format=zip&api-version=5.0"
     $outPathAgents = Join-Path -Path $outPath -ChildPath $appPath.Split("/")[-1]
 
      Try{
             Invoke-RestMethod -Uri $uri -Method Get -ContentType "application/zip" -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -OutFile $outPathAgents
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
             [System.IO.Compression.ZipFile]::ExtractToDirectory($outPathAgents, $installPath)
             LogWrite "Descompresion exitosa en $installPath"
         }
         Catch{
             LogWrite "Fallo al descomprimir:   $_.Exception "
             Break
         }
 #Step 3
 #TO DO Recursive or defined?

 ((Get-Content -path "$($installPath)Automic\Agents\windows\bin\UCXJWX6.ini" -Raw) -replace 'CLAROAGENT',$agentName) | Set-Content -Path "$($installPath)Automic\Agents\windows\bin\UCXJWX6.ini"
 ((Get-Content -path "$($installPath)Automic\Agents\windows\bin\UCXJWX6.ini" -Raw) -replace '172.26.28.23','172.23.3.191') | Set-Content -Path "$($installPath)Automic\Agents\windows\bin\UCXJWX6.ini"
 ((Get-Content -path "$($installPath)Automic\ServiceManager\bin\uc4.smc" -Raw) -replace 'CLAROAGENT',$agentName) | Set-Content -Path "$($installPath)Automic\ServiceManager\bin\uc4.smc"
 ((Get-Content -path "$($installPath)Automic\ServiceManager\bin\UC4.smd" -Raw) -replace 'CLAROAGENT',$agentName) | Set-Content -Path "$($installPath)Automic\ServiceManager\bin\UC4.smd"
 ((Get-Content -path "$($installPath)Automic\Agents\windows\bin\UCXJWX6.kstr" -Raw) -replace 'CLAROAGENT',$agentName) | Set-Content -Path "$($installPath)Automic\Agents\windows\bin\UCXJWX6.kstr"
 

 #Step 4
     LogWrite "Configurando CAPKI ........."
     & "$($installPath)Automic\CAPKI\x64\setup.exe" install caller=AE122 verbose env=all 
 
     LogWrite "Configurando SM"
     & "$($installPath)Automic\ServiceManager\bin\UCYBSMgr.exe" -install UC4
 
     Start-Service -Name "UC4.ServiceManager.UC4" 
