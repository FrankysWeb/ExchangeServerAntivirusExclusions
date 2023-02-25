# Generate list of exclusions for antivirus software on Exchange 2013/2016/2019 servers

These PowerShell scripts generate a list of file, folder, process file extension exclusions for configuring antivirus software that will be running on an Exchange 2013 or Exchange 2016 servers. The correct exclusions are recommended to prevent antivirus software from interfering with the operation of Exchange Server.

The scripts are based on information published by Microsoft:

- [Exchange Server 2013 antivirus exclusions](https://technet.microsoft.com/en-us/library/bb332342(v=exchg.150).aspx)
- [Exchange Server 2016 antivirus exclusions](https://technet.microsoft.com/en-us/library/bb332342(v=exchg.160).aspx)
- [Exchange Server 2019 antivirus exclusions](https://learn.microsoft.com/en-us/Exchange/antispam-and-antimalware/windows-antivirus-software?redirectedfrom=MSDN&view=exchserver-2019)

Use the scripts to generate the exclusion list based on a single server. You can then apply the same exclusions to all servers that have the same configuration. If your antivirus software has a policy-based administration console then that can make the configuration of multiple servers more efficient.

**Run the script in the Exchange Management Shell locally on the server you wish to generate the exclusions list for**.

## Download

You can download the scripts from the [Github](https://github.com/FrankysWeb/ExchangeServerAntivirusExclusions).

## Usage

For Exchange 2013 servers:

```
.\Get-Exchange2013AVExclusions.ps1
```

For Exchange 2016 servers:

```
.\Get-Exchange2016AVExclusions.ps1
```

For Exchange 2016 servers running on Windows Server 2016 (and Exchange Server 2019):

```
.\Get-Exchange2016AVExclusions.ps1 -ConfigureWindowsDefender
```

Results are output to text files, which you can import or manually enter in your antivirus configuration.

## Credits
Written by: Paul Cunningham
Modified by: Frank Zoechling (Original script was archived and readonly)

Find me on:

* My Blog:	https://paulcunningham.me
* Twitter:	https://twitter.com/paulcunningham
* LinkedIn:	https://au.linkedin.com/in/cunninghamp/
* Github:	https://github.com/cunninghamp

Check out my [books](https://paulcunningham.me/books/) and [courses](https://paulcunningham.me/training/) to learn more about Office 365 and Exchange Server.

Additional credit:

* Matt K (via [blog comment](http://exchangeserverpro.com/powershell-script-exchange-2013-antivirus-exclusions/#comment-244497))
* Frank Zoechling [FrankysWeb](https://www.frankysweb.de)
