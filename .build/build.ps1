$builder = New-Object -TypeName "System.Text.StringBuilder"

foreach ($priv in $(Get-ChildItem -Path "$PSScriptRoot\..\src\private" -Filter *.ps1 -Recurse)) {
    [void] $builder.AppendLine((Get-Content -Path $priv.FullName -Raw))
    [void] $builder.AppendLine()
}

$aliases = New-Object -TypeName 'System.Collections.Generic.List[string]'

[string[]] $functionsToExport = foreach ($pub in Get-ChildItem -Path "$PSScriptRoot\..\src\public" -Filter *.ps1) {

    [string[]] $content = Get-Content -Path $pub.FullName
    
    for ($i = 0; $i -lt $content.Count; $i++) {

        $line = $content[$i]

        if ($line -like "Function*") {
            [void] $builder.AppendLine(($content[$i..$($content.Count - 1)] -join "`n"))
            break
        }

        if ($line -like "#*Alias:*") {

            $regex = [regex]::Match($line, 'Alias\:\s*((?:\w+|\,)+)', "IgnoreCase")

            if ($regex.Success) {
                $aliases.AddRange($regex.Groups[1].Value.Split([string[]]@(','), "RemoveEmptyEntries"))
            }
        }
    }

    [void] $builder.AppendLine()

    [System.IO.Path]::GetFileNameWithoutExtension($pub.Name)
}

Set-Content -Path "$PSScriptRoot\..\src\PoshChoco.psm1" -Value $builder.ToString() -Force 
$manifest = "$PSScriptRoot\..\src\PoshChoco.psd1"

$updArgs = @{
    Path              = $manifest
    FunctionsToExport = $functionsToExport
    AliasesToExport   = $aliases
}

Update-ModuleManifest @updArgs
Test-ModuleManifest -Path $manifest