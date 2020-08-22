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
        [string[]] $InputObject
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

        if ($PSBoundParameters.ContainsKey("InputObject")) {

            $set.UnionWith($InputObject)
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

    [CmdletBinding()]
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
    }
    Process {
        $set.UnionWith($Exception)
    }
    End {
        
        if (-not $set.SetEquals($current)) {
            
            $cmd = "--value='{0}'" -f ($set -join ',');
            $result = choco config set --limit-output --name='upgradeAllExceptions' $cmd;
            $result
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
    [string[]] $current = $output -split ','

    if ($null -ne $Exception -and $Exception.Length -gt 0) {
        $current.Where({
            $x = $_
            $Exception | Any { $x -like $_ }
        })
    }
    else {
        $current
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

    [CmdletBinding()]
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
    }
    Process {
        $set.ExceptWith($Exception)
    }
    End {

        if (-not $set.SetEquals($current)) {
            
            $cmd = "--value='{0}'" -f ($set -join ',')
            choco config set --name='upgradeAllExceptions' $cmd
        }
        else {
            Write-Warning 'The exceptions were not modified due to no differences.'
        }
    }
}

#endregion

