$myWinId = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$myPrinId = New-Object System.Security.Principal.WindowsPrincipal($myWinId)
$adm = [System.Security.Principal.WindowsBuiltInRole]::Administrator
if (-not ($myPrinId.IsInRole($adm))) {
	Write-Warning "This module is intended to be run from an elevated shell.`nRunning as an standard user cause unexpected behavior."
}

#region PRIVATE FUNCTIONS

Function Filter-Object() {

    [CmdletBinding(PositionalBinding = $false)]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object[]] $InputObject,

        [Parameter(Mandatory = $true, Position = 0)]
        [string[]] $By,

        [Parameter(Mandatory = $false, Position = 1)]
        [string] $PropertyToFilter = "Name"
    )
    Begin {
        $objects = New-List -GenericType [object] -Capacity 2
    }
    Process {

        if ((Test-Collection $InputObject)) {
            $objects.AddRange($InputObject)
        }
    }
    End {
        $objects.Where({
            $property = $_."$PropertyToFilter"
            $By | Assert-Any { $property -like $_ }
        })
    }
}

Function New-StringHashSet() {

    [CmdletBinding()]
    [OutputType([System.Collections.Generic.HashSet[string]])]
    param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string[]] $Add
    )
    Begin {

        $setArgs = @{
            GenericType    = [string]
            Capacity       = 2
            EqualityScript = { $x -eq $y }
            HashCodeScript = { $_.ToLower().GetHashCode() }
        }
        
        $set = New-HashSet @setArgs
    }
    Process {

        if ($PSBoundParameters.ContainsKey("Add")) {

            $set.UnionWith($Add)
        }
    }
    End {
        , $set
    }
}

Function Resolve-ChocoPackage() {

    param (
        [Parameter(Mandatory=$true, Position = 0, ValueFromPipeline=$true)]
        [string[]] $ChocoLines
    )
    Process {
        

        foreach ($line in $ChocoLines) {

            New-Variable -Name 'tryVersion' -Scope 'Private' #-ErrorAction 'SilentlyContinue'

            $split = $line.Split([string[]]@('|'), 'RemoveEmptyEntries')

            $firstSegment = $($split | Select-Object -First 1).Trim()
            $lastSegment = $($split | Select-Object -Last 1).Trim()

            if ($firstSegment -ne $lastSegment -and [Version]::TryParse($lastSegment, [ref] $tryVersion)) {

                $use = $tryVersion   
            }
            else {
                $use = [string]::Empty
            }

            [pscustomobject]@{
                Name    = $firstSegment
                Version = $use
            }
            Remove-Variable -Name 'tryVersion' -Scope Private -Force
        }
    }
}

Function Test-Collection() {

    param (
        [Parameter(Mandatory=$true, Position = 0)]
        [object[]] $Collection
    )
    $null -ne $Collection -and $Collection.Count -gt 0
}

#endregion

#region PUBLIC FUNCTIONS

Function Add-ChocoException() {

    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact = "Low")]
    param (
        [Parameter(Mandatory = $true, Position = 0,
            ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias("Name")]
        [string[]] $Exception,

        [Parameter(Mandatory = $false)]
        [switch] $PassThru
    )
    Begin {

        $output = choco config get --limit-output --name='upgradeAllExceptions'
        [string[]] $current = $output.Split([string[]]@(','), "RemoveEmptyEntries")
        $set = New-StringHashSet -Add $current
        $excepts = New-StringHashSet
    }
    Process {
        $excepts.UnionWith($Exception)
    }
    End {
        
        $set.UnionWith($excepts)
        
        if (-not $set.SetEquals($current)) {
        
            if ($PSCmdlet.ShouldProcess(($excepts -join ', '), "Add Exception")) {

                $cmd = "--value='{0}'" -f ($set -join ',')
                $result = choco config set --no-color --limit-output --name='upgradeAllExceptions' $cmd
                Write-Verbose $result

                if ($PassThru) {

                    foreach ($app in $set) {
                        [pscustomobject]@{
                            Name = $app
                        }
                    }
                }
            }
        }
        else {
            Write-Warning 'The exceptions were not modified due to no differences being found.'
        }
    }
}

Function Get-ChocoException() {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [SupportsWildcards()]
        [string[]] $Exception
    )

    $output = choco config get --limit-output --name='upgradeAllExceptions'
    if ([string]::IsNullOrWhitespace($output)) {
        return
    }

    [string[]] $current = $output -split ','

    if ($null -ne $Exception -and $Exception.Length -gt 0) {
        $current = $current.Where({
            $x = $_
            $Exception | Any { $x -like $_ }
        })
    }
    
    foreach ($package in $current) {
        [pscustomobject]@{
            Name = $package
        }
    }
}

Function Get-ChocoPackage() {

    [CmdletBinding()]
    [Alias("chocolist")]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [string[]] $Name
    )

    [string[]] $output = choco list --local-only --limit-output

    [array] $packages = Resolve-ChocoPackage -ChocoLines $output

    if ($null -ne $Name -and $Name.Length -ge 0) {

        $packages | Filter-Object -By $Name
    }
    else {
        $packages
    }
}

Function Remove-ChocoException() {

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "Low")]
    param (
        [Parameter(Mandatory = $true, Position = 0,
            ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias("Name")]
        [string[]] $Exception
    )
    Begin {

        $output = choco config get --limit-output --name='upgradeAllExceptions'
        [string[]] $current = $output.Split([string[]]@(','), "RemoveEmptyEntries")
        $set = New-StringHashSet -Add $current
        $excepts = New-StringHashSet
    }
    Process {
        $excepts.UnionWith($Exception)
    }
    End {

        $set.ExceptWith($excepts)
        
        if (-not $set.SetEquals($current)) {
            
            if ($PSCmdlet.ShouldProcess(($excepts -join ', '), "Remove Exception")) {

                $cmd = "--value='{0}'" -f ($set -join ',')
                $result = choco config set --no-color --limit-output --name='upgradeAllExceptions' $cmd
                Write-Verbose $result
            }
        }
        else {
            Write-Warning 'The exceptions were not modified due to no differences.'
        }
    }
}

#endregion

