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