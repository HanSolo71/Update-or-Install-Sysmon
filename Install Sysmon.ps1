
Variables
#Gets computers to run on from text file
#$computers = Get-Content '\\FileShare\Computers.txt'

#Gets all workstations that need to have software installed, if you don't want to uninstall all of the software from you will need to use a text document and Get-Content
$computers = Get-ADComputer -Filter * -SearchBase "OU=SERVERS,DC=CONTOSO,DC=COM" | Select DNSHostName -ExpandProperty DNSHostname


$SysmonV6Location = '\\FileShare\Sysmon64-V6.exe'
$SysmonV7Location = '\\FileShare\Sysmon64-V7.exe'
$SysmonXMLLocation = '\\FileShare\sysmonconfig-export.xml'


foreach ($computer in $computers) 
{
Write-Output "`r`n I am installing Sysmon on $Computer"
#Create Temp Directory
New-Item \\$Computer\C$\Temp -ItemType directory
#Copy Previous Sysmon version to temp directory
Copy-Item $SysmonV6Location \\$computer\C$\Temp
#Copy New Sysmon version to temp directory
Copy-Item $SysmonV7Location \\$computer\C$\Temp
#Copy Sysmon XML configuration document to temp directory
Copy-Item $SysmonXMLLocation \\$computer\C$\Temp
#Kill any running instances of sysmon
Invoke-Command -ComputerName $computer -ScriptBlock {taskkill /f /im sysmon*}
#Uninstall old Sysmon version
Invoke-Command -ComputerName $computer -ScriptBlock {C:\Temp\Sysmon64-V6 -u}
#Uninstall current version of sysmon
Invoke-Command -ComputerName $computer -ScriptBlock {C:\Temp\Sysmon64-V7 -u}
#Delete any leftover remanants of sysmon
Invoke-Command -ComputerName $computer -ScriptBlock {del C:\Windows\Sysmon*}
#Install new sysmon version with XML configuration file
Invoke-Command -ComputerName $computer -ScriptBlock {C:\Temp\Sysmon64-V7.exe -accepteula -i C:\Temp\sysmonconfig-export.xml}
#Cleanup
Invoke-Command -ComputerName $computer -ScriptBlock {del C:\Temp\sysmon*}
Invoke-Command -ComputerName $computer -ScriptBlock {del C:\Temp\PsExec*}
#Ensures all sysmon logs start being sent to graylog
Invoke-Command -ComputerName $computer -ScriptBlock {Restart-Service -DisplayName "nxlog*"}
}