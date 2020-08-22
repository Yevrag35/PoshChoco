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