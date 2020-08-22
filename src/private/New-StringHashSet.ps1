Function New-StringHashSet() {

    [CmdletBinding()]
    [OutputType([System.Collections.Generic.HashSet[string]])]
    param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string[]] $Add
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

        if ($PSBoundParameters.ContainsKey("Add")) {

            $set.UnionWith($Add)
        }
    }
    End {
        , $set
    }
}