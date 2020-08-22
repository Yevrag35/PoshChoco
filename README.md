# <img height="30px" src="./.media/poshchoco.png" alt="PoshChoco"></img> PoshChoco

[![version](https://img.shields.io/powershellgallery/v/PoshChoco.svg?include_prereleases)](https://www.powershellgallery.com/packages/PoshChoco)
[![downloads](https://img.shields.io/powershellgallery/dt/PoshChoco.svg?label=downloads)](https://www.powershellgallery.com/stats/packages/PoshChoco?groupby=Version)

## What is this?

I'm making this module to make certain tasks with the chocolatey executable a little more friendly and PowerShell-like.  Results from choco.exe are turned into PowerShell objects.

Currently, this module will let you see what packages you have installed and what 'upgradeAllExceptions' are set (as well as modify it).  Function results can piped back and forth between other functions.

---

## Requirements

1. [Must have chocolatey installed](https://chocolatey.org/install)
1. Windows PowerShell 5.1 or PowerShell Core (6.x - 7.x)
1. My other module [ListFunctions (v1.1)](https://www.powershellgallery.com/packages/ListFunctions/1.1) must be installed.  _(NOTE: installing PoshChoco from the gallery will automatically download and install ListFunctions as well.)_

## Functions

* __Add-ChocoException__ _(choco config set --name='upgradeAllExceptions')_
* __Get-ChocoException__ _(choco config get --name='upgradeAllExceptions')_
* __Get-ChocoPackage__ _(choco list --local-only)_
* __Remove-ChocoException__ _(same as 'Add-ChocoException')_

### Examples

Show which .NET Framework and SDK's are installed:
```powershell
Get-ChocoPackage dotnetfx, "netfx*-devpack"

# Name                  Version
# ----                  -------
# dotnetfx              4.8.0.20190930
# netfx-4.6.2-devpack   4.6.01590.20190930
# netfx-4.8-devpack     4.8.0.20190930
```

Add all KB article packages to the 'upgradeAllExceptions' list:
```powershell
Get-ChocoPackage KB* | Add-ChocoException -Verbose
# VERBOSE: Updated upgradeAllExceptions = KB2670838,KB2919442,KB2999226,KB3033929,KB3035131,KB3118401,KB2919355
```

Remove all KB packages from the 'upgradeAllExceptions' that are currently set:
```powershell
Get-ChocoException KB* | Remove-ChocoException
```
