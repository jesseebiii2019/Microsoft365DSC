function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Key,

        [Parameter()]
        [System.String]
        $Value,

        [Parameter()]
        [ValidateSet("Tenant", "Site")]
        [System.String]
        $EntityScope = "Tenant",

        [Parameter()]
        [System.String]
        $Comment,

        [Parameter()]
        [System.String]
        $Description,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter(Mandatory = $true)]
        [System.String]
        $SiteUrl,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $GlobalAdminAccount,

        [Parameter()]
        [System.String]
        $ApplicationId,

        [Parameter()]
        [System.String]
        $TenantId,

        [Parameter()]
        [System.String]
        $CertificatePath,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $CertificatePassword,

        [Parameter()]
        [System.String]
        $CertificateThumbprint
    )

    Write-Verbose -Message "Getting configuration for SPO Storage Entity for $Key"
    #region Telemetry
    $data = [System.Collections.Generic.Dictionary[[String], [String]]]::new()
    $data.Add("Resource", $MyInvocation.MyCommand.ModuleName)
    $data.Add("Method", $MyInvocation.MyCommand)
    Add-M365DSCTelemetryEvent -Data $data
    #endregion

    $ConnectionMode = New-M365DSCConnection -Platform 'PNP' -InboundParameters $PSBoundParameters `
        -ConnectionUrl $SiteUrl

    $nullReturn = @{
        Key                   = $Key
        Value                 = $Value
        EntityScope           = $EntityScope
        Description           = $Description
        Comment               = $Comment
        Ensure                = "Absent"
        SiteUrl               = $SiteUrl
        GlobalAdminAccount    = $GlobalAdminAccount
        ApplicationId         = $ApplicationId
        TenantId              = $TenantId
        CertificatePassword   = $CertificatePassword
        CertificatePath       = $CertificatePath
        CertificateThumbprint = $CertificateThumbprint
    }

    Write-Verbose -Message "Getting storage entity $Key"

    $entityStorageParms = @{ }
    $entityStorageParms.Add("Key", $Key)

    if ($null -ne $EntityScope -and "" -ne $EntityScope)
    {
        $entityStorageParms.Add("Scope", $EntityScope)
    }

    $Entity = Get-PnPStorageEntity @entityStorageParms -ErrorAction SilentlyContinue
    ## Get-PnPStorageEntity seems to not return $null when not found
    ## so checking key
    if ($null -eq $Entity.Key)
    {
        Write-Verbose -Message "No storage entity found for $Key"
        return $nullReturn
    }

    Write-Verbose -Message "Found storage entity $($Entity.Key)"

    return @{
        Key                   = $Entity.Key
        Value                 = $Entity.Value
        EntityScope           = $EntityScope
        Description           = $Entity.Description
        Comment               = $Entity.Comment
        Ensure                = "Present"
        SiteUrl               = $SiteUrl
        GlobalAdminAccount    = $GlobalAdminAccount
        ApplicationId         = $ApplicationId
        TenantId              = $TenantId
        CertificatePassword   = $CertificatePassword
        CertificatePath       = $CertificatePath
        CertificateThumbprint = $CertificateThumbprint
    }
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Key,

        [Parameter()]
        [System.String]
        $Value,

        [Parameter()]
        [ValidateSet("Tenant", "Site")]
        [System.String]
        $EntityScope = "Tenant",

        [Parameter()]
        [System.String]
        $Comment,

        [Parameter()]
        [System.String]
        $Description,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter(Mandatory = $true)]
        [System.String]
        $SiteUrl,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $GlobalAdminAccount,

        [Parameter()]
        [System.String]
        $ApplicationId,

        [Parameter()]
        [System.String]
        $TenantId,

        [Parameter()]
        [System.String]
        $CertificatePath,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $CertificatePassword,

        [Parameter()]
        [System.String]
        $CertificateThumbprint
    )

    Write-Verbose -Message "Setting configuration for SPO Storage Entity for $Key"
    #region Telemetry
    $data = [System.Collections.Generic.Dictionary[[String], [String]]]::new()
    $data.Add("Resource", $MyInvocation.MyCommand.ModuleName)
    $data.Add("Method", $MyInvocation.MyCommand)
    Add-M365DSCTelemetryEvent -Data $data
    #endregion

    $ConnectionMode = New-M365DSCConnection -Platform 'PNP' -InboundParameters $PSBoundParameters `
        -ConnectionUrl $SiteUrl

    $curStorageEntry = Get-TargetResource @PSBoundParameters

    $CurrentParameters = $PSBoundParameters
    $CurrentParameters.Remove("SiteUrl") | Out-Null
    $CurrentParameters.Remove("GlobalAdminAccount") | Out-Null
    $CurrentParameters.Remove("Ensure") | Out-Null
    $CurrentParameters.Remove("EntityScope") | Out-Null
    $CurrentParameters.Remove("ApplicationId") | Out-Null
    $CurrentParameters.Remove("TenantId") | Out-Null
    $CurrentParameters.Remove("CertificatePath") | Out-Null
    $CurrentParameters.Remove("CertificatePassword") | Out-Null
    $CurrentParameters.Remove("CertificateThumbprint") | Out-Null
    $CurrentParameters.Add("Scope", $EntityScope)

    if (($Ensure -eq "Absent" -and $curStorageEntry.Ensure -eq "Present"))
    {
        Write-Verbose -Message "Removing storage entity $Key"
        Remove-PnPStorageEntity -Key $Key
    }
    elseif ($Ensure -eq "Present")
    {
        try
        {
            Write-Verbose -Message "Adding new storage entity $Key"
            Set-PnPStorageEntity @CurrentParameters
        }
        catch
        {
            if ($_.Exception -like "*Access denied*")
            {
                throw "It appears that the account doesn't have access to create an SPO Storage " + `
                    "Entity or that an App Catalog was not created for the specified location"
            }
        }
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Key,

        [Parameter()]
        [System.String]
        $Value,

        [Parameter()]
        [ValidateSet("Tenant", "Site")]
        [System.String]
        $EntityScope = "Tenant",

        [Parameter()]
        [System.String]
        $Comment,

        [Parameter()]
        [System.String]
        $Description,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter(Mandatory = $true)]
        [System.String]
        $SiteUrl,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $GlobalAdminAccount,

        [Parameter()]
        [System.String]
        $ApplicationId,

        [Parameter()]
        [System.String]
        $TenantId,

        [Parameter()]
        [System.String]
        $CertificatePath,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $CertificatePassword,

        [Parameter()]
        [System.String]
        $CertificateThumbprint
    )

    Write-Verbose -Message "Testing configuration for SPO Storage Entity for $Key"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-M365DscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-M365DscHashtableToString -Hashtable $PSBoundParameters)"

    $TestResult = Test-Microsoft365DSCParameterState -CurrentValues $CurrentValues `
        -Source $($MyInvocation.MyCommand.Source) `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck @("Key", `
            "Value", `
            "Key", `
            "Comment", `
            "Description", `
            "EntityScope", `
            "Ensure")

    Write-Verbose -Message "Test-TargetResource returned $TestResult"

    return $TestResult
}

function Export-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter()]
        [System.Management.Automation.PSCredential]
        $GlobalAdminAccount,

        [Parameter()]
        [System.String]
        $ApplicationId,

        [Parameter()]
        [System.String]
        $TenantId,

        [Parameter()]
        [System.String]
        $CertificatePath,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $CertificatePassword,

        [Parameter()]
        [System.String]
        $CertificateThumbprint
    )
    $InformationPreference = 'Continue'

    #region Telemetry
    $data = [System.Collections.Generic.Dictionary[[String], [String]]]::new()
    $data.Add("Resource", $MyInvocation.MyCommand.ModuleName)
    $data.Add("Method", $MyInvocation.MyCommand)
    Add-M365DSCTelemetryEvent -Data $data
    #endregion

    $ConnectionMode = New-M365DSCConnection -Platform 'PNP' -InboundParameters $PSBoundParameters

    $storageEntities = Get-PnPStorageEntity -ErrorAction SilentlyContinue

    $i = 1
    $content = ''
    $organization = ""
    $principal = "" # Principal represents the "NetBios" name of the tenant (e.g. the M365DSC part of M365DSC.onmicrosoft.com)
    $organization = Get-M365DSCOrganization -GlobalAdminAccount $GlobalAdminAccount -TenantId $Tenantid
    if ($organization.IndexOf(".") -gt 0)
    {
        $principal = $organization.Split(".")[0]
    }

    # Obtain central administration url from a User Principal Name
    if ($ConnectionMode -eq 'Credential')
    {
        $centralAdminUrl = Get-SPOAdministrationUrl -GlobalAdminAccount $GlobalAdminAccount
    }
    else
    {
        $centralAdminUrl = "https://$principal-admin.sharepoint.com"
    }
    foreach ($storageEntity in $storageEntities)
    {
        if ($ConnectionMode -eq 'Credential')
        {
            $params = @{
                GlobalAdminAccount = $GlobalAdminAccount
                Key                = $storageEntity.Key
                SiteUrl            = $centralAdminUrl
            }
        }
        else
        {
            $params = @{
                Key                   = $storageEntity.Key
                SiteUrl               = $centralAdminUrl
                ApplicationId         = $ApplicationId
                TenantId              = $TenantId
                CertificatePassword   = $CertificatePassword
                CertificatePath       = $CertificatePath
                CertificateThumbprint = $CertificateThumbprint
            }
        }


        Write-Information "    [$i/$($storageEntities.Length)] $($storageEntity.Key)"
        $result = Get-TargetResource @params
        if ($ConnectionMode -eq 'Credential')
        {
            $result.GlobalAdminAccount = Resolve-Credentials -UserName "globaladmin"
        }
        else
        {
            if ($null -ne $CertificatePassword)
            {
                $result.CertificatePassword = Resolve-Credentials -UserName "CertificatePassword"
            }
        }
        $result = Remove-NullEntriesFromHashTable -Hash $result
        $content += "        SPOStorageEntity " + (New-Guid).ToString() + "`r`n"
        $content += "        {`r`n"
        $partialContent = Get-DSCBlock -Params $result -ModulePath $PSScriptRoot
        if ($ConnectionMode -eq 'Credential')
        {
            $partialContent = Convert-DSCStringParamToVariable -DSCBlock $partialContent -ParameterName "GlobalAdminAccount"
        }
        else
        {
            if ($null -ne $CertificatePassword)
            {
                $partialContent = Convert-DSCStringParamToVariable -DSCBlock $partialContent -ParameterName "CertificatePassword"
            }
            $partialContent = Format-M365ServicePrincipalData -configContent $partialContent -applicationid $ApplicationId `
                -principal $principal -CertificateThumbprint $CertificateThumbprint
        }
        if ($partialContent.ToLower().Contains("https://" + $principal.ToLower()))
        {
            # If we are already looking at the Admin Center URL, don't replace the full path;
            if ($partialContent.ToLower().Contains("https://" + $principal.ToLower() + "-admin.sharepoint.com"))
            {
                $partialContent = $partialContent -ireplace [regex]::Escape("https://" + $principal.ToLower() + "-admin.sharepoint.com"), "https://`$(`$OrganizationName.Split('.')[0])-admin.sharepoint.com"
            }
            else
            {
                $partialContent = $partialContent -ireplace [regex]::Escape("https://" + $principal.ToLower()), "`$(`$OrganizationName.Split('.')[0])-admin.sharepoint.com"
            }
        }
        $content += $partialContent
        $content += "        }`r`n"
        $i++
    }
    return $content
}

Export-ModuleMember -Function *-TargetResource
