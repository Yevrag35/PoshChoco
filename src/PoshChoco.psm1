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
