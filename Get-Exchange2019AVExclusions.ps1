<#
.SYNOPSIS
Get-Exchange2016AVExclusions.ps1 - Generate list of exclusions for antivirus software.

.DESCRIPTION 
This PowerShell script generates a list of file, folder, process file extension exclusions
for configuring antivirus software that will be running on an Exchange 2016 server. The 
correct exclusions are recommended to prevent antivirus software from interfering with
the operation of Exchange.

This script is based on information published by Microsoft here:
https://technet.microsoft.com/en-us/library/bb332342(v=exchg.160).aspx
https://techcommunity.microsoft.com/t5/exchange-team-blog/update-on-the-exchange-server-antivirus-exclusions/ba-p/3751464

Use this script to generate the exclusion list based on a single server. You can then
apply the same exclusions to all servers that have the same configuration. If your antivirus
software has a policy-based administration console then that can make the configuration
of multiple servers more efficient.

Run the script in the Exchange Management Shell locally on the server you wish to generate
the exclusions list for.

.OUTPUTS
Results are output to text files.

.EXAMPLE
.\Get-Exchange2016AVExclusions.ps1

.NOTES
Written by: Paul Cunningham
Modified by: Frank Zoechling

Find me on:

* My Blog:	https://paulcunningham.me
* Twitter:	https://twitter.com/paulcunningham
* LinkedIn:	https://au.linkedin.com/in/cunninghamp/
* Github:	https://github.com/cunninghamp

Additional credit:

* Matt K (via http://exchangeserverpro.com/powershell-script-exchange-2013-antivirus-exclusions/#comment-244497)

Change Log:
V1.00, 05/05/2016 - Initial version
V1.01, 02/25/23 - Modified exclusions to new best practise (https://techcommunity.microsoft.com/t5/exchange-team-blog/update-on-the-exchange-server-antivirus-exclusions/ba-p/3751464)
V1.02, 01/02/25 - Testet with Windows Server 2025 and Exchange 2019 CU14, modified exclusions to best practises
License:

The MIT License (MIT)

Copyright (c) 2016 Paul Cunningham

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
#>

#requires -version 3


[CmdletBinding()]
param (
	
	[Parameter( Mandatory=$false)]
	[switch]$ConfigureWindowsDefender

	)


#...................................
# Variables
#...................................
#
# Three separate text files are created by the script. Microsoft recommends
# configuring file/folder, process, and file types in case one method of 
# exclusion fails, or in case a path changes later when the server is
# reconfigured.
#

$server = $ENV:ComputerName

[bool]$IsMailbox = (Get-ExchangeServer -Identity $env:computername).IsMailboxServer
[bool]$IsEdge = (Get-ExchangeServer -Identity $env:computername).IsEdgeServer

#This text file lists the file and folder paths to exclude from antivirus scanning.
$outputfile_paths = "av-exclusions-$($server)-paths.txt"

#This text file lists the processes to exclude from antivirus scanning.
$outputfile_procs = "av-exclusions-$($server)-procs.txt"

#This test file lists the file extensions to exclude from antivirus scanning.
$outputfile_extensions = "av-exclusions-$($server)-extensions.txt"


#...................................
# Script
#...................................

# Start the file/folder paths text file
"### Antivirus exclusion paths for $server ###" | Out-File $outputfile_paths
"" | Out-File $outputfile_paths -Append


### Mailbox Servers ###
if ($IsMailbox) {

    #Cluster

    "$($env:windir)\Cluster" | Out-File $outputfile_paths -Append


    #OAB

    "$($exinstall)ClientAccess\OAB" | Out-File $outputfile_paths -Append


    #Malware and DLP scanning

    "$($exinstall)FIP-FS" | Out-File $outputfile_paths -Append


    #Group Metrics

    "$($exinstall)GroupMetrics" | Out-File $outputfile_paths -Append


    #Log files

    $serverlogs = Get-MailboxServer $server | Select DataPath,CalendarRepairLogPath,LogPathForManagedFolders,MigrationLogFilePath,`
                                                        TransportSyncLogFilePath,TransportSyncMailboxHealthLogFilePath

    $names = @($serverlogs | Get-Member | Where {$_.membertype -eq "NoteProperty"})
    foreach ($name in $names) {$serverlogs.($name.Name).PathName | Out-File $outputfile_paths -Append}

    (Get-PopSettings).LogFileLocation | Out-File $outputfile_paths -Append

    (Get-ImapSettings).LogFileLocation | Out-File $outputfile_paths -Append


    #Databases

    $databases = @(Get-MailboxDatabase -Server $server | Sort Name | Select EdbFilePath,LogFolderPath)

    $databases.EdbFilePath.PathName | Out-File $outputfile_paths -Append

    $databases.LogFolderPath.PathName | Out-File $outputfile_paths -Append


    #FE Transport

    $fetransport = @(Get-FrontEndTransportService $server | Select *logpath*)

    $names = @($fetransport | Get-Member | Where {$_.membertype -eq "NoteProperty"})

    foreach ($name in $names) {$fetransport.($name.Name).PathName | Out-File $outputfile_paths -Append}


    #Mailbox Transport

    $mailboxtransport = @(Get-MailboxTransportService $server | Select *logpath*)

    $names = @($mailboxtransport | Get-Member | Where {$_.membertype -eq "NoteProperty"})

    foreach ($name in $names) {$mailboxtransport.($name.Name).PathName | Out-File $outputfile_paths -Append}


    #Unified Messaging
    #Grammars

    "$($exinstall)UnifiedMessaging\grammars" | Out-File $outputfile_paths -Append

    #Voice prompts

    "$($exinstall)UnifiedMessaging\Prompts" | Out-File $outputfile_paths -Append

    #Voice mail

    "$($exinstall)UnifiedMessaging\voicemail" | Out-File $outputfile_paths -Append

    #Temp

    "$($exinstall)UnifiedMessaging\temp" | Out-File $outputfile_paths -Append


    #Web Components

    "$($env:SystemDrive)\inetpub\temp\IIS Temporary Compressed Files" | Out-File $outputfile_paths -Append

}

### Edge Transport Servers ###
if ($IsEdge) {

    #ADAM
    "$($exinstall)TransportRoles\Data\Adam" | Out-File $outputfile_paths -Append

}

## Edge and Mailbox Servers ###

if ($IsEdge -or $IsMailbox) {

    #Queue and DB files#

    $xmlfile = "$($exinstall)Bin\EdgeTransport.exe.config"

    if (!(Test-Path $xmlfile)) {
        Write-Host "EdgeTransport.exe.config file not found"
    }
    else {
    
        [xml]$edgetransportconfig = Get-Content $xmlfile

        $ETConfigPaths = @()

        foreach ($item in $edgetransportconfig.configuration.appSettings.add)
        {
            if ($item.key -eq "QueueDatabasePath")
            {
                $QueueDatabasePath = $item.value
                if (!($ETConfigPaths -contains $QueueDatabasePath))
                {
                    $ETConfigPaths += $QueueDatabasePath
                }
            }

            if ($item.key -eq "QueueDatabaseLoggingPath")
            {
                $QueueDatabaseLoggingPath = $item.value
                if (!($ETConfigPaths -contains $QueueDatabaseLoggingPath))
                {
                    $ETConfigPaths += $QueueDatabaseLoggingPath
                }        
            }

            if ($item.key -eq "IPFilterDatabasePath")
            {
                $IPFilterDatabasePath = $item.value
                if (!($ETConfigPaths -contains $IPFilterDatabasePath))
                {
                    $ETConfigPaths += $IPFilterDatabasePath
                }    
            }

            if ($item.key -eq "IPFilterDatabaseLoggingPath")
            {
                $IPFilterDatabaseLoggingPath = $item.value
                if (!($ETConfigPaths -contains $IPFilterDatabaseLoggingPath))
                {
                    $ETConfigPaths += $IPFilterDatabaseLoggingPath
                }    
            }
        }

        $ETConfigPaths | Out-File $outputfile_paths -Append
    }


    #Sender Reputation database, checkpoint, and log files
    "$($exinstall)TransportRoles\Data\SenderReputation" | Out-File $outputfile_paths -Append


    ### Transport Services ###

    $transportservice = Get-TransportService $server | Select ConnectivityLogPath,MessageTrackingLogPath,IrmLogPath,ActiveUserStatisticsLogPath,`
                                            ServerStatisticsLogPath,ReceiveProtocolLogPath,RoutingTableLogPath,SendProtocolLogPath,`
                                            QueueLogPath,WlmLogPath,AgentLogPath,FlowControlLogPath,ProcessingSchedulerLogPath,`
                                            ResourceLogPath,DnsLogPath,JournalLogPath,TransportMaintenanceLogPath,PipelineTracingPath,`
                                            PickupDirectoryPath,ReplayDirectoryPath,RootDropDirectoryPath

    $names = @($transportservice | Get-Member | Where {$_.membertype -eq "NoteProperty"})

    foreach ($name in $names) {$transportservice.($name.Name).PathName | Out-File $outputfile_paths -Append}


    #Content conversions

    "$($env:windir)\temp" | Out-File $outputfile_paths -Append
    "$($exinstall)Working\OleConverter" | Out-File $outputfile_paths -Append

}


### Process Exclusions ###

#Start the process exclusions text file
"### Antivirus exclusion procs for $server ###" | Out-File $outputfile_procs
"" | Out-File $outputfile_procs -Append

if ($IsMailbox) {

    "$($exinstall)Bin\ComplianceAuditService.exe" | Out-File $outputfile_procs -Append
    "$($exinstall)FIP-FS\Bin\fms.exe" | Out-File $outputfile_procs -Append
    "$($exinstall)Bin\Search\Ceres\HostController\hostcontrollerservice.exe" | Out-File $outputfile_procs -Append
    "$($env:SystemRoot)\System32\inetsrv\inetinfo.exe" | Out-File $outputfile_procs -Append
    "$($exinstall)Bin\Microsoft.Exchange.Directory.TopologyService.exe" | Out-File $outputfile_procs -Append
    "$($exinstall)Bin\Microsoft.Exchange.EdgeSyncSvc.exe" | Out-File $outputfile_procs -Append
    "$($exinstall)FrontEnd\PopImap\Microsoft.Exchange.Imap4.exe" | Out-File $outputfile_procs -Append
    "$($exinstall)ClientAccess\PopImap\Microsoft.Exchange.Imap4service.exe" | Out-File $outputfile_procs -Append
    "$($exinstall)Bin\Microsoft.Exchange.Notifications.Broker.exe" | Out-File $outputfile_procs -Append
    "$($exinstall)FrontEnd\PopImap\Microsoft.Exchange.Pop3.exe" | Out-File $outputfile_procs -Append
    "$($exinstall)ClientAccess\PopImap\Microsoft.Exchange.Pop3service.exe" | Out-File $outputfile_procs -Append
    "$($exinstall)Bin\Microsoft.Exchange.ProtectedServiceHost.exe" | Out-File $outputfile_procs -Append
    "$($exinstall)Bin\Microsoft.Exchange.RPCClientAccess.Service.exe" | Out-File $outputfile_procs -Append
    "$($exinstall)Bin\Microsoft.Exchange.Search.Service.exe" | Out-File $outputfile_procs -Append
    "$($exinstall)Bin\Microsoft.Exchange.Store.Service.exe" | Out-File $outputfile_procs -Append
    "$($exinstall)Bin\Microsoft.Exchange.Store.Worker.exe" | Out-File $outputfile_procs -Append
    "$($exinstall)FrontEnd\CallRouter\Microsoft.Exchange.UM.CallRouter.exe" | Out-File $outputfile_procs -Append
    "$($exinstall)Bin\MSExchangeCompliance.exe" | Out-File $outputfile_procs -Append
    "$($exinstall)Bin\MSExchangeDagMgmt.exe" | Out-File $outputfile_procs -Append
    "$($exinstall)Bin\MSExchangeDelivery.exe" | Out-File $outputfile_procs -Append
    "$($exinstall)Bin\MSExchangeFrontendTransport.exe" | Out-File $outputfile_procs -Append
    "$($exinstall)Bin\MSExchangeMailboxAssistants.exe" | Out-File $outputfile_procs -Append
    "$($exinstall)Bin\MSExchangeMailboxReplication.exe" | Out-File $outputfile_procs -Append
    "$($exinstall)Bin\MSExchangeRepl.exe" | Out-File $outputfile_procs -Append
    "$($exinstall)Bin\MSExchangeSubmission.exe" | Out-File $outputfile_procs -Append
    "$($exinstall)Bin\MSExchangeThrottling.exe" | Out-File $outputfile_procs -Append
    "$($exinstall)Bin\Search\Ceres\Runtime\1.0\Noderunner.exe" | Out-File $outputfile_procs -Append
    "$($exinstall)Bin\OleConverter.exe" | Out-File $outputfile_procs -Append
    "$($exinstall)Bin\Search\Ceres\ParserServer\ParserServer.exe" | Out-File $outputfile_procs -Append
    "$($exinstall)FIP-FS\Bin\ScanEngineTest.exe" | Out-File $outputfile_procs -Append
    "$($exinstall)FIP-FS\Bin\ScanningProcess.exe" | Out-File $outputfile_procs -Append
    "$($exinstall)Bin\UmService.exe" | Out-File $outputfile_procs -Append
    "$($exinstall)Bin\UmWorkerProcess.exe" | Out-File $outputfile_procs -Append
    "$($exinstall)FIP-FS\Bin\UpdateService.exe" | Out-File $outputfile_procs -Append
    "$($exinstall)Bin\wsbexchange.exe" | Out-File $outputfile_procs -Append
}

if ($IsEdge) {

    "$($env:SystemRoot)\System32\Dsamain.exe" | Out-File $outputfile_procs -Append
    "$($exinstall)Bin\Microsoft.Exchange.EdgeCredentialSvc.exe" | Out-File $outputfile_procs -Append
}

if ($IsMailbox -or $IsEdge) {

    "$($exinstall)Bin\EdgeTransport.exe" | Out-File $outputfile_procs -Append
    "$($exinstall)Bin\Microsoft.Exchange.AntispamUpdateSvc.exe" | Out-File $outputfile_procs -Append
    "$($exinstall)TransportRoles\agents\Hygiene\Microsoft.Exchange.ContentFilter.Wrapper.exe" | Out-File $outputfile_procs -Append
    "$($exinstall)Bin\Microsoft.Exchange.Diagnostics.Service.exe" | Out-File $outputfile_procs -Append
    "$($exinstall)Bin\Microsoft.Exchange.Servicehost.exe" | Out-File $outputfile_procs -Append
    "$($exinstall)Bin\MSExchangeHMHost.exe" | Out-File $outputfile_procs -Append
    "$($exinstall)Bin\MSExchangeHMWorker.exe" | Out-File $outputfile_procs -Append
    "$($exinstall)Bin\MSExchangeTransport.exe" | Out-File $outputfile_procs -Append
    "$($exinstall)Bin\MSExchangeTransportLogSearch.exe" | Out-File $outputfile_procs -Append
}


### File Extension Exclusions ###

# Start the file type exclusions text file
"### Antivirus exclusion extensions for $server ###" | Out-File $outputfile_extensions
"" | Out-File $outputfile_extensions -Append

if ($IsMailbox) {

    ".dsc" | Out-File $outputfile_extensions -Append
    ".txt" | Out-File $outputfile_extensions -Append
    ".cfg" | Out-File $outputfile_extensions -Append
    ".grxml" | Out-File $outputfile_extensions -Append
    ".lzx" | Out-File $outputfile_extensions -Append
}

if ($IsEdge -or $IsMailbox) {

    ".config" | Out-File $outputfile_extensions -Append
    ".chk" | Out-File $outputfile_extensions -Append
    ".edb" | Out-File $outputfile_extensions -Append
    ".jfm" | Out-File $outputfile_extensions -Append
    ".jrs" | Out-File $outputfile_extensions -Append
    ".log" | Out-File $outputfile_extensions -Append
    ".que" | Out-File $outputfile_extensions -Append
}


#Configure Windows Defender

if ($ConfigureWindowsDefender) {

    if (@(Get-Module Defender -ListAvailable).Count -gt 0) {
        write-Host -ForegroundColor Green "Windows Defender PowerShell module available."

        $ExclusionPathsList = @(Get-Content $outputfile_paths | Where {$_.ReadCount -gt 2})
        foreach ($ExclusionPath in $ExclusionPathsList) {
            try {
                Add-MpPreference -ExclusionPath $ExclusionPath
            }
            catch {
                Write-Warning $_.Exception.Message
            }
        }

        $ExclusionProcsList = @(Get-Content $outputfile_procs | Where {$_.ReadCount -gt 2})
        foreach ($ExclusionProc in $ExclusionProcsList) {
            try {
                Add-MpPreference -ExclusionProcess $ExclusionProc
            }
            catch {
                Write-Warning $_.Exception.Message
            }
        }

        $ExclusionExtList = @(Get-Content $outputfile_extensions | Where {$_.ReadCount -gt 2})
        foreach ($ExclusionExt in $ExclusionExtList) {
            try {
                Add-MpPreference -ExclusionExtension $ExclusionExt
            }
            catch {
                Write-Warning $_.Exception.Message
            }
        }
        
    } else {
        Write-Warning "Windows Defender PowerShell module not available."
    }

}


Write-Host "Done."

#...................................
# Finished
#...................................
