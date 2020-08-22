Function New-StringHashSet() {

    [CmdletBinding()]
    [OutputType([System.Collections.Generic.HashSet[string]])]
    param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string[]] $InputObject
    )
    Begin {

        $setArgs = @{
            GenericType    = [string]
            Capacity       = 2
            EqualityScript = { $x -eq $y }
            HashCodeScript = { $_.ToLower().GetHashCode() }
        }
        
        $set = New-HashSet @setArgs
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