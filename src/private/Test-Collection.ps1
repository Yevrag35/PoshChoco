Function Test-Collection() {

    param (
        [Parameter(Mandatory=$true, Position = 0)]
        [object[]] $Collection
    )
    $null -ne $Collection -and $Collection.Count -gt 0
}