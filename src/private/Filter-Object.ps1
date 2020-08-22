Function Filter-Object() {

    [CmdletBinding(PositionalBinding = $false)]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object[]] $InputObject,

        [Parameter(Mandatory = $true, Position = 0)]
        [string[]] $By,

        [Parameter(Mandatory = $false, Position = 1)]
        [string] $PropertyToFilter = "Name"
    )
    Begin {
        $objects = New-List -GenericType [object] -Capacity 2
    }
    Process {

        if ((Test-Collection $InputObject)) {
            $objects.AddRange($InputObject)
        }
    }
    End {
        $objects.Where({
            $property = $_."$PropertyToFilter"
            $By | Assert-Any { $property -like $_ }
        })
    }
}