Function NewStringHashSet() {

    [CmdletBinding()]
    [OutputType([System.Collections.Generic.HashSet[string]])]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string[]] $InputObject
    )
    Begin {
        $set = New-Object -TypeName 'System.Collections.Generic.HashSet[string]'
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