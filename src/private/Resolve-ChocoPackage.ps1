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