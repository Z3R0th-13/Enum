# Just a simple script to do some basic enumeration of a target system. 
#
# ******************************************************************
# ******************************************************************
# **                                                              **
# **                           Enum                               **
# **                    Written by: Z3R0th                        **
# **                                                              **
# **                                                              **
# ******************************************************************
# ******************************************************************

# Print the time this script was ran. Useful for knowing access times. 
$Access = Get-Date
Write-Output "[***] You ran this script on $Access [***]"

# Determine OS running on target
$ComputerName = $env:computername
$OS = (Get-WmiObject -Class Win32_OperatingSystem -ComputerName $ComputerName | select caption | select-string windows)-split("=", "}", "{")[0] -replace "}"| select-string windows
If ($OS -match "10") {Write-Output "[*] You are running $OS"}
If ($OS -match " 8") {Write-Output "[*] You are running $OS"}
If ($OS -match " 7") {Write-Output "[*] You are running $OS"}
if ($OS -match "2016") {Write-Output "[*] You are running $OS"}
If ($OS -match "2012") {Write-Output "[*] You are running $OS"}
If ($OS -match "2008") {Write-Output "[*] You are running $OS"}

# Check Execution Policy on target
$Execute = Get-ExecutionPolicy
Write-Output "[*] The Execution Policy is set to $Execute"

# Look and see if there is a startup folder for the user you are
$StartUp = test-path $env:homepath\appdata\roaming\microsoft\windows\start` menu\programs\startup
If ($StartUp -eq "True") {Write-Output "[*] A Startup folder exists at $env:homepath\appdata\roaming\microsoft\windows\start` menu\programs\startup!"} Else {Write-Output "[*] There is no startup folder :c"}

# Determine if running in a 32 or 64 bit environment
If ((Get-WmiObject -Class Win32_OperatingSystem -ComputerName $ENV:Computername).OSArchitecture -eq '64-bit') {
	$PSPath = "$($ENV:Systemroot)\SYSWOW64\WindowsPowershell\v1.0\powershell.exe"; Write-Output "[*] You are in a 64 bit machine!"} 
Else {
	$PSPath = "$PSHome\powershell.exe"; Write-Output "[*] You are in a 32 bit machine!"}

# Check if running as Administrator
$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
If ($IsAdmin) {Write-Output "[*] Running with Administrator Privileges! GO HACK ALL THE THINGS!"} Else {Write-Output "[*] You're stuck in userland, better escalate!"}

# Get Principal Name
$PrincipalName = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
Write-Output "[*] You are $PrincipalName"

# Get the Domain you are in
$Domain = cat env:userdomain
Write-Output "[*] You are in the $Domain domain"

# Get current IPv4 Address
$IP = (ipconfig | select-string IPv4)-split(":")[-1] | findstr [0-9].\.
Write-Output "[*] Your IP is$IP"

# Print which PowerShell Version you're currently running
$Version = $PSVersionTable.PSVersion.Major
Write-Output "[*] You are running PowerShell Version $Version"
If ($Version -eq "2"){Write-Output "[*] You should be clear to exploit"} Else {Write-Warning "[*] Switch to PowerShell Version 2 by running 'powershell -versio 2 -STA -nopr -nonin'"}

# Figure out which apartment state you're currently running
$Apartment = [System.Threading.Thread]::CurrentThread.GetApartmentState() 
#Write-Output "[*] You're running in $Apartment"
If ($Apartment -eq "STA"){Write-Output "[*] You're running in a Single Threaded Apartment State, you should be good to run Get-System"}
Else {Write-Warning "[*] You're running in a Multi-Threaded Apartment State. It's recommended you switch to Single Threaded with 'powershell.exe -STA -versio 2 -nopr -nonin'"}

# Find the Explorer Process and PID. Useful for Cobalt Strike when capturing Keystrokes and Screenshots
$Explore = get-process -name explorer | select -expand id
Write-Output "[*] The PID for Explorer is $Explore, use this with Cobalt Strike's keylogger and screenshot grabber"

# Query for currently logged in users and whether or not they are active
Write-Output "[*] The following users are currently logged in"
If ($OS -match "7") {$Current = query user | fl | out-host}
# Windows 10 use this
Else {Get-WmiObject -Class Win32_ComputerSystem | select username}

# List shares available
Write-Output "[*] The following shares are available"
PSdrive | select-object * -exclude used, free, provider, credential, currentlocation | fl

#List mapped drives
Write-Output "[*] The following drives have been mapped to the system"
Get-WmiObject -Class Win32_MappedLogicalDisk | select Name, ProviderName

# List Local Admins
Write-Output "[*] These users are also local Administrators!"
$ADSIComputer = [ADSI] ("WinNT://$ComputerName, computer")
$Group = $ADSIComputer.psbase.children.find("Administrators", "Group")
net localgroup Administrators

# Check whether or not SMBv1 is enabled or disabled. 
$SMBCheck = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Lanmanserver\Parameters" -Name SMB1 -ErrorAction SilentlyContinue | Select-Object "SMB1")
if ( $SMBCheck -match "0" ) {Write-Host "SMBv1 is currently disabled"} Elseif ( $SMBCheck -match "1" ) {Write-Host "SMBv1 is enabled!"} Else {Write-Host "I don't see the key for SMBv1..."}
