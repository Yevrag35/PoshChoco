Function Get-ChocoException() {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [SupportsWildcards()]
        [Alias("Name")]
        [string[]] $Exception
    )
    Begin {
        $set = New-StringHashSet
    }
    Process {
        $set.UnionWith($Exception)
    }
    End {

        $output = choco config get --limit-output --name='upgradeAllExceptions'
        if ([string]::IsNullOrWhitespace($output)) {
            return
        }

        [string[]] $current = $output -split ','

        if ($null -ne $Exception -and $Exception.Length -gt 0) {

            $current = $current.Where({
                $x = $_
                $set | Any { $x -like $_ }
            })
        }

        foreach ($package in $current) {

            [pscustomobject]@{
                Name = $package
            }
        }
    }
}