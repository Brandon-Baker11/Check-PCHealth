#This function will run a simple diagnostic if a device's performance has degraded it will provide:
#The up-time of the device
#The resource consumption for the system's memory, and display the processes utilizing those resources
#The available local drive space for the device
#The machine group policy file and update if necessary

function Check-PCHealth {
    param([String][Parameter(Mandatory=$True,Position=0)] $pcname)
    Import-Module ActiveDirectory
    #If the target computer can be reached all of the data from the computer will be assigned to the variables below
    if (Test-Connection $pcname -Quiet) {
        $uptime = (Get-Date) - (Get-CimInstance Win32_OperatingSystem -ComputerName $pcname).LastBootUpTime
        $cpu = Get-WmiObject Win32_processor -ComputerName $pcname | Select-Object -property LoadPercentage, Name, NumberOfCores
        $memory = Get-WmiObject Win32_OperatingSystem -ComputerName $pcname | Select-Object -Property TotalVisibleMemorySize, FreePhysicalMemory
        $disk = Get-WmiObject -Class:Win32_LogicalDisk -ComputerName $pcname -Filter "DeviceID='C:'" | Select-Object Size, FreeSpace
        $days = $uptime.days
        $hours =  $uptime.hours
        $minutes = $uptime.minutes
        $totalmemory = [Math]::Round($memory.totalvisiblememorysize /1MB,2) #Using /1MB gives accurate memory measurement in GB for some reason
        $freememory = [Math]::Round($memory.FreePhysicalMemory /1MB,2)
        $percentmemoryfree = [int]([float]($freememory / $totalmemory) * 100)
        $disksize = [Math]::Round($disk.size /1GB)
        $diskfree = [Math]::Round($disk.freespace /1GB)
        $percentdiskfree = [int]([float]($diskfree / $disksize) * 100)
        $macpolicy =  Get-ChildItem "\\$pcname\C$\Windows\System32\GroupPolicy\Machine\Registry.pol" | Select-Object LastWriteTime
        $macdate = $macpolicy.LastWriteTime.ToShortDateString()
        

       
        #Checks the up-time for the given device and recommends powercycle if uptime is -ge 3 days
        if ($days -ge 3) {
            $uptimeaction = "This device has been running for $days days, $hours hours and $minutes minutes! Recommend powercycling device."
        }
        else {
            $uptimeaction = ""
        }

        #Checks the system's memory utilization and lists the most resource intensive processes
        if ($percentmemoryfree -le 10) {
            $memoryaction = "This device has only $percentmemoryfree percent memory available! See the list of processes with the highest resource utilization."
        }
        else {
            $memoryaction = ""
        }
        
        #Checks the C: drive's available disk space
        if ($percentdiskfree -le 10) {
            $diskaction = "This device's local drive only has $percentdiskfree percent free space available! Recommend having the user delete some files they don't need or transferring them to an external drive."
        }
        else {
            $diskaction = ""
        }
    
        #Checks the system's machine Group Policy and updates if over a week old
        if ($macdate -le (Get-Date).AddDays(-7)) {
            Write-Host "Machine Group Policy is out of date, updating Group Policy"
            Invoke-Command -ComputerName $pcname -ScriptBlock {gpupdate /force}
            $gpaction = "This machine's group policy was outdated, group policy has been updated."
        }
        else {
            $gpaction = ""
        }
    }
    else {
        Write-Host "`n Unable to establish connection with target computer."
    }
    
    #Outputs
    Write-Host "`nComputer Name:              " $pcname.ToUpper()
    Write-Host "Uptime:                     " "$days days $hours hours and $minutes minutes"
    Write-Host "Last Machine Policy Update: " $macdate
    Write-Host "Total System Memory:        " $totalmemory"GB"
    Write-Host "System Memory Available:    " $freememory"GB"
    write-host "Local Disk Size:            " $disksize"GB"
    write-host "Local Disk Space Available: " $diskfree"GB"
    Write-Host "`n---------------------------"


    if (($uptimeaction -ne "") -or ($memoryaction -ne "") -or ($diskaction -ne "") -or ($gpaction -ne "")) {
        Write-Host "`nTroubleshooting reccomendations:"
    
        if ($gpaction -ne "") {
            Write-Host $gpaction
        }
        if ($uptimeaction -ne "") {
            Write-Host "$uptimeaction"
        }
        if ($memoryaction -ne "") {
            Write-Host "$memoryaction"
        }
        if ($diskaction -ne "") {
            Write-Host "$diskaction"
        }
        if ($memoryaction -ne "") {
            Write-Host "`nBuilding list of high utilization processes..."
            Start-Sleep -Seconds 3
            Invoke-Command -ComputerName $pcname -ScriptBlock {Get-Process | Sort-Object -Property CPU -Descending | Select-Object -First 5}
        }
    }
    else {
        Write-Host "`nThis device's performance is within normal standards. Continue troubleshooting to find the source of your issue."
    }
    
    
}