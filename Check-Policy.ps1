function Check-Policy {
    param(
        [String][Parameter(Mandatory=$True,Position=0)] $ComputerName
        )
        Import-Module ActiveDirectory

        if (Test-Connection $ComputerName -Quiet) {
            if (Test-Path -Path "\\$computername\c$\Windows\System32\GroupPolicy\Machine\Registry.pol") {
                $macpolicy =  Get-ChildItem "\\$ComputerName\c$\Windows\System32\GroupPolicy\Machine\Registry.pol" | Select-Object LastWriteTime
                $macdate = $macpolicy.LastWriteTime.ToShortDateString()
                if ($macdate -le (Get-Date).AddDays(-7)) {
                    Write-Host "Updating this computer's Group Policy..."
                    Invoke-Command -ComputerName $ComputerName -ScriptBlock {gpupdate /force}
                    }
                    else {Write-Host "This computer's Group Policy was last updated $macdate"}
                }
                else {
                Write-Host "File not found, refreshing policy."
                Invoke-Command -ComputerName $ComputerName -ScriptBlock {gpupdate /force}
                }
        }
        else {Write-Host "This computer is offline."}
}


