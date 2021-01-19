<#
-----------------------------------------------------------------------------------------------------------------
Description: Script post installation puppet sur Azure Windows 2019 et Windows 2016
Createur: Clegrand@integra.fr
Version: 1.0
Puppet Agent version: 5.5.8
-----------------------------------------------------------------------------------------------------------------
#>

# Variables
$HostName = $args[0]
$BastionIp = $args[1]
$PuppetAgentVersion='https://downloads.puppetlabs.com/windows/puppet5/puppet-agent-5.5.8-x64.msi'
$LogFile = 'C:\windows\temp\integra_post_install.log'
$HostFile = 'C:\windows\System32\drivers\etc\hosts'
$PuppetConfFile = 'C:\ProgramData\PuppetLabs\puppet\etc\puppet.conf'


# Modification ficher host

"$BastionIp kickstart.itc.integra.fr" | Add-Content -PassThru $HostFile
"$BastionIp puppet5.itc.integra.fr" | Add-Content -PassThru $HostFile

# Creation dossier necessaire a l'installation de puppet
New-Item -Path "C:\" -Name "applications" -ItemType Directory -Force
New-Item -Path "C:\" -Name "production" -ItemType Directory -Force
New-Item -Path "C:\applications\" -Name "puppet" -ItemType Directory -Force

# Configuration disk production

Get-Disk | Where partitionstyle -eq 'raw' |
    Initialize-Disk -PartitionStyle MBR -PassThru |
    New-Partition -AssignDriveLetter -UseMaximumSize |
    Format-Volume -FileSystem NTFS -NewFileSystemLabel "production" -Confirm:$false

# Arguments MSI 
# Pour activer les logs msi decommentez les deux lignes commentées dans MSIArguments

$MSIArguments = @(
#    '/L*v',
#    $LogFile,
    'SYMREBOOT=ReallySuppress',
    '/qn',
    '/i',
    $PuppetAgentVersion,
    'PUPPET_MASTER_SERVER=puppet5.itc.integra.fr',
    'INSTALLDIR="c:\applications\puppet\"'
)

# Installation Agent Puppet V5
Start-Process -FilePath "msiexec" -ArgumentList $MSIArguments -Wait


# Configuration puppet 

"masterport=8141" | Add-Content -PassThru $PuppetConfFile
"reportport=8141" | Add-Content -PassThru $PuppetConfFile
"certname=$HostName" | Add-Content -PassThru $PuppetConfFile


# Arguments Puppet command
$PuppetArguments = @(
	'agent',
	'-t'
)
# Run puppet agent -t
# Start-Process "puppet" -ArgumentList $PuppetArguments

# Start service puppet
Start-Service puppet





