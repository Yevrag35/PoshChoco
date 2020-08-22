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
        $current.Where({
            $x = $_
            $Exception | Any { $x -like $_ }
        })
    }
    else {
        $current
    }
}