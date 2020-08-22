Function Add-Line() {
    param (
        [Parameter(Mandatory=$false)]
        [System.Text.StringBuilder] $StringBuilder = $builder,

        [Parameter(Mandatory=$false, ValueFromPipeline=$true, Position=0)]
        [string[]] $Line
    )
    Process {
        if ($null -eq $Line -or $Line.Count -le 0) {
            [void] $StringBuilder.AppendLine()
            break
        }

        foreach ($singleLine in $Line) {
            [void] $StringBuilder.AppendLine($singleLine)
        }
    }
}
Function Add-Disclaimer() {
    param (
        [Parameter(Mandatory=$false)]
        [System.Text.StringBuilder] $StringBuilder = $builder
    )
    @(
        '$myWinId = [System.Security.Principal.WindowsIdentity]::GetCurrent()',
        '$myPrinId = New-Object System.Security.Principal.WindowsPrincipal($myWinId)',
        '$adm = [System.Security.Principal.WindowsBuiltInRole]::Administrator',
        'if (-not ($myPrinId.IsInRole($adm))) {',
        "`tWrite-Warning `"This module is intended to be run from an elevated shell.``nRunning as an standard user cause unexpected behavior.`"",
        "}",
        ''
    ) | Add-Line -StringBuilder $StringBuilder
}

$builder = New-Object -TypeName 'System.Text.StringBuilder'
Add-Disclaimer

'#region PRIVATE FUNCTIONS', '' | Add-Line

foreach ($priv in $(Get-ChildItem -Path "$PSScriptRoot\..\src\private" -Filter *.ps1 -Recurse)) {

    @((Get-Content -Path $priv.FullName -Raw), '') | Add-Line
}

'#endregion', '', '#region PUBLIC FUNCTIONS', '' | Add-Line

$aliases = New-Object -TypeName 'System.Collections.Generic.List[string]'

[string[]] $functionsToExport = foreach ($pub in Get-ChildItem -Path "$PSScriptRoot\..\src\public" -Filter *.ps1) {

    [string[]] $content = Get-Content -Path $pub.FullName
    
    for ($i = 0; $i -lt $content.Count; $i++) {

        $line = $content[$i]

        if ($line -like "Function*") {

            $content[$i..$($content.Count - 1)] | Add-Line
            break
        }

        if ($line -like "#*Alias:*") {

            $regex = [regex]::Match($line, 'Alias\:\s*((?:\w+|\,)+)', 'IgnoreCase')

            if ($regex.Success) {
                $aliases.AddRange($regex.Groups[1].Value.Split([string[]]@(','), 'RemoveEmptyEntries'))
            }
        }
    }

    Add-Line ''

    [System.IO.Path]::GetFileNameWithoutExtension($pub.Name)
}

'#endregion' | Add-Line

Set-Content -Path "$PSScriptRoot\..\src\PoshChoco.psm1" -Value $builder.ToString() -Force 
$manifest = "$PSScriptRoot\..\src\PoshChoco.psd1"

$updArgs = @{
    Path              = $manifest
    FunctionsToExport = $functionsToExport
    AliasesToExport   = $aliases
}

Update-ModuleManifest @updArgs
Test-ModuleManifest -Path $manifest | Select-Object -Property *