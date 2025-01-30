# Check-PCHealth
This is a tool that I wrote in PowerShell that will allow a technician to check the statistics of a remote computer. This tool will collect the following data from the target computer:
- Device Name
- Uptime
- Last Machine Group Policy Update
- Total System Memory
- System Memory Available
- Local Disk Size
- Local Disk Space Available

With this information, the script will display any actions that could be performed if certain parameters are met (e.g. the script will perform a gp update if current is older than a week.)

## Technologies Used
- PowerShell


## Operating Systems Used
- Windows 11 Enterprise (23H2)

## Deployment and Configuration Steps
