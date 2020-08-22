#region PRIVATE
Function New-StringHashSet([string[]] $Add) {

    $equal = { $x -eq $y }
    $hash = { $_.ToLower().GetHashCode() }
    $hashArgs = @{
        GenericType    = [string]
        Capacity       = $Add.Length
        EqualityScript = $equal
        HashCodeScript = $hash
    }
    if ($null -ne $Add -and $Add.Length -gt 0) {
        $hashArgs.Add("InputObject", $Add)
    }

    , $(New-HashSet @hashArgs)
}

#endregion

Function Get-ChocoPackage() {

    [CmdletBinding()]
    [Alias("chocolist")]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [string[]] $Name
    )
    [string[]] $output = choco list --local-only --limit-output
    New-Variable -Name tryVers -Scope Private

    $pkgs = foreach ($line in $output) {
        $split = $line.Split([string[]]@('|'), "RemoveEmptyEntries")

        if ([Version]::TryParse($split[1], [ref] $tryVers)) {
            $use = $tryVers
        }
        else {
            $use = $split[1]
        }

        [pscustomobject]@{
            Name    = $split[0]
            Version = $use
        }
    }

    if ($null -ne $Name -and $Name.Length -ge 0) {
        $pkgs.Where({
            $x = $_.Name
            $Name | Any { $x -like $_ }
        })
    }
    else {
        $pkgs
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
            $cmd = "--value='{0}'" -f ($set -join ',')
            choco config set --limit-output --name='upgradeAllExceptions' $cmd
        }
        else {
            Write-Warning 'The exceptions were not modified due to no differences.'
        }
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

