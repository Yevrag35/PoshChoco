# Alias: chocolist

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