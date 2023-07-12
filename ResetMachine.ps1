#Install-Module AzureAD -Force
#Install-Module Microsoft.graph -Force
#Install-Module -Name "PnP.PowerShell" -RequiredVersion 1.12.0 -Force -AllowClobber

$Comp = "NameHERE"

# Load required modules
Import-Module Microsoft.Graph.Intune -ErrorAction Stop
Import-Module AzureAD -ErrorAction Stop


# Authenticate with Azure
Write-Host "Authenticating with MS Graph and Azure AD..." -NoNewline
        $intuneId = Connect-MSGraph -ErrorAction Stop
        $aadId = Connect-AzureAD -AccountId $intuneId.UPN -ErrorAction Stop
        Write-host "Success" -ForegroundColor Green
Write-host "$($Comp.ToUpper())" -ForegroundColor Yellow
Write-Host "===============" -ForegroundColor Yellow

# Initiate Wipe From Intune
Write-host "Retrieving " -NoNewline
        Write-host "Intune " -ForegroundColor Yellow -NoNewline
        Write-host "managed device record/s..." -NoNewline
        [array]$IntuneDevices = Get-IntuneManagedDevice -Filter "deviceName eq '$Comp'" -ErrorAction Stop
        If ($IntuneDevices.Count -ge 1)
        {
            Write-Host "Success" -ForegroundColor Green
            foreach ($IntuneDevice in $IntuneDevices)
                {
                    Invoke-IntuneManagedDeviceSyncDevice -managedDeviceId $IntuneDevice.Id -Verbose -ErrorAction Stop
                    Invoke-IntuneManagedDeviceWipeDevice -managedDeviceId $IntuneDevice.Id -Verbose -ErrorAction Stop


                    Write-host "Success" -ForegroundColor Green
                }
            }
        
        Else
        {
            Write-host "Not found!" -ForegroundColor Red
}

sleep 600

# Delete from AD
 Write-host "Retrieving " -NoNewline
        Write-host "Active Directory " -ForegroundColor Yellow -NoNewline
        Write-host "computer account..." -NoNewline   
        $Searcher = [ADSISearcher]::new()
        $Searcher.Filter = "(sAMAccountName=$Comp`$)"
        [void]$Searcher.PropertiesToLoad.Add("distinguishedName")
        $ComputerAccount = $Searcher.FindOne()
        If ($ComputerAccount)
        {
            Write-host "Success" -ForegroundColor Green
            Write-Host "   Deleting computer account..." -NoNewline
            $DirectoryEntry = $ComputerAccount.GetDirectoryEntry()
            $Result = $DirectoryEntry.DeleteTree()
            Write-Host "Success" -ForegroundColor Green
        }
        Else
        {
            Write-host "Not found!" -ForegroundColor Red
        }

# Delete from Azure AD
Write-host "Retrieving " -NoNewline
        Write-host "Azure AD " -ForegroundColor Yellow -NoNewline
        Write-host "device record/s..." -NoNewline 
        [array]$AzureADDevices = Get-AzureADDevice -SearchString $Comp -All:$true -ErrorAction Stop
        If ($AzureADDevices.Count -ge 1)
        {
            Write-Host "Success" -ForegroundColor Green
            Foreach ($AzureADDevice in $AzureADDevices)
            {
                Write-host "   Deleting DisplayName: $($AzureADDevice.DisplayName)  |  ObjectId: $($AzureADDevice.ObjectId)  |  DeviceId: $($AzureADDevice.DeviceId) ..." -NoNewline
                Remove-AzureADDevice -ObjectId $AzureADDevice.ObjectId -ErrorAction Stop
                Write-host "Success" -ForegroundColor Green
            }      
        }
        Else
        {
            Write-host "Not found!" -ForegroundColor Red
        }

# Delete from Intune
Write-host "Retrieving " -NoNewline
        Write-host "Intune " -ForegroundColor Yellow -NoNewline
        Write-host "managed device record/s..." -NoNewline
        [array]$IntuneDevices = Get-IntuneManagedDevice -Filter "deviceName eq '$Comp'" -ErrorAction Stop
        If ($IntuneDevices.Count -ge 1)
        {
            Write-Host "Success" -ForegroundColor Green
            foreach ($IntuneDevice in $IntuneDevices)
                {
                    Write-host "   Deleting DeviceName: $($IntuneDevice.deviceName)  |  Id: $($IntuneDevice.Id)  |  AzureADDeviceId: $($IntuneDevice.azureADDeviceId)  |  SerialNumber: $($IntuneDevice.serialNumber) ..." -NoNewline
                    Remove-IntuneManagedDevice -managedDeviceId $IntuneDevice.Id -Verbose -ErrorAction Stop
                    Write-host "Success" -ForegroundColor Green
                }
            }
        
        Else
        {
            Write-host "Not found!" -ForegroundColor Red
}