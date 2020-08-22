foreach ($priv in $(Get-ChildItem -Path "$PSScriptRoot\..\src\private" -Filter *.ps1 -Recurse)) {

    . $priv.FullName
}

foreach ($pub in $(Get-ChildItem -Path "$PSScriptRoot\..\src\public" -Filter *.ps1)) {

    . $pub.FullName
}