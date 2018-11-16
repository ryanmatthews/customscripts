<#
.SYNOPSIS
This PowerShell script will enumerate all VMs in an SLA and initate an On-Demand snapshot for any VMs that have no exiting snapshots
.DESCRIPTION
.EXAMPLE
.\Protect-VMsNoSnaps.ps1 -rubrikNode sand1-rbk01.rubrikdemo.com -rubrikSLA 'SLA'
.NOTES
Writen by Ryan Matthews for community usage

To prepare to use this script complete the following steps:
1) Download the Rubrik Powershell module from Github or the Powershell Library.
  a) Install-Module Rubrik
  b) Import-Module Rubrik
  c) Install VMWare PowerCLI

.LINK
https://github.com/ryanmatthews
https://github.com/rubrikinc/PowerShell-Module
#>


[CmdletBinding()]
param(
  # The IP address or hostname of a node in the Rubrik cluster.
  [Parameter(Mandatory=$True,
  HelpMessage="Enter the IP address or hostname of a node in the Rubrik Cluster.")]
  [string]$rubrikNode,
  # The SLA Domain to run On Demands for
  [Parameter(Mandatory=$True,
  HelpMessage="Enter the SLA name.")]
  [string]$rubrikSLA
)

#Load Rubrik module and connect
Import-Module Rubrik

#Connect to Rubrik cluster
Connect-Rubrik -Server $rubrikNode

#To avoid the credentials pop-up and run non-interactive 
#create a credentials file for connecting to Rubrik (Typically a domain account) using the following
#  a) $cred = Get-Credential
#    i) Enter the domain credentials to use for this script.
#  b) $cred | Export-Clixml C:\temp\RubrikCred.xml -Force
#and then uncomment the line below and comment out the Connect-Rubrik line above
#Connect-Rubrik -Server $rubrikNode -Credential (Import-Clixml $creds)


$VMlist = Get-RubrikVM -SLA $rubrikSLA
$VMlist.id | ForEach-Object {
  $vmDetails = Get-RubrikVM -id $_
  Write-Output $('working with '+ $vmDetails.Name)
  if ($vmDetails.snapshotCount -eq 0) {
    Write-Output "  no snapshots found. taking on-demand backup"
    New-RubrikSnapshot -id $vmDetails.id -SLA $rubrikSLA -Confirm:$false
  } else {
    Write-Output $('  found '+ $vmDetails.snapshotCount + ' snapshots. Nothing to do.')
  }
}

Disconnect-Rubrik
