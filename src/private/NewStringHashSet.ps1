Function NewStringHashSet() {

    [CmdletBinding()]
    [OutputType([System.Collections.Generic.HashSet[string]])]
    param (
        [Parameter(Mandatory=$false, ValueFromPipeline=$true)]
        [string[]] $InputObject
    )
    Begin {
        $comparer = New-Object -TypeName 'PoshChoco.IgnoreCaseEquality'
        $set = New-Object -TypeName 'System.Collections.Generic.HashSet[string]'($comparer)
    }
    Process {
        if ($PSBoundParameters.ContainsKey("InputObject")) {
            $set.UnionWith($InputObject)
        }
    }
    End {
        , $set
    }
}