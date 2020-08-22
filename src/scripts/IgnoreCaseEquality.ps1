$code = @"
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Management.Automation;

namespace PoshChoco
{
    public class IgnoreCaseEquality : IEqualityComparer<string>
    {
        public bool Equals(string x, string y)
        {
            if (x != null && y != null)
            {
                return x.Equals(y, StringComparison.CurrentCultureIgnoreCase);
            }
            else if (x == null && y != null)
            {
                return false;
            }
            else if (x != null && y == null)
            {
                return false;
            }
            else
            {
                return true;
            }
        }
        public int GetHashCode(string x)
        {
            return x.ToLower().GetHashCode();
        }
    }
}
"@

$atArgs = @{
    TypeDefinition       = $code
    Language             = "CSharp"
    ReferencedAssemblies = @(
        "System", 
        "System.Collections",
        "System.Management.Automation", 
        "System.Linq"
    )
}

Add-Type @atArgs