# escape=`
FROM mcr.microsoft.com/windows/servercore/iis:windowsservercore-ltsc2022

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'Continue'; $verbosePreference='Continue';"]

# Enable Windows Authentication
RUN Install-WindowsFeature Web-Windows-Auth –IncludeAllSubFeature

# Install .NET
ENV DOTNET_VERSION 7.0.10
ENV DOTNET_DOWNLOAD_URL https://download.visualstudio.microsoft.com/download/pr/d489c5d0-4d0f-4622-ab93-b0f2a3e92eed/101a2fae29a291956d402377b941f401/dotnet-hosting-7.0.10-win.exe

ENV DOTNET_DOWNLOAD_SHA cd52c9d45e63458ce1e84282b2d9b1432ced7ecfdbe1b3d57b3f0791d20c2ecfcc7ffb8da0916722cea4cce55cb5dea8f34bff489f7a04c14c104a974ff72379
RUN Invoke-WebRequest $Env:DOTNET_DOWNLOAD_URL -OutFile WindowsHosting.exe; `
    if ((Get-FileHash WindowsHosting.exe -Algorithm sha512).Hash -ne $Env:DOTNET_DOWNLOAD_SHA) { `
    Write-Host 'CHECKSUM VERIFICATION FAILED!'; `
    exit 1; `
    }; `
    `
    dir c:\Windows\Installer; `
    Start-Process "./WindowsHosting.exe" '/install /quiet /norestart' -Wait; `
    Remove-Item -Force -Recurse 'C:\ProgramData\Package Cache\*'; `
    Remove-Item -Force -Recurse C:\Windows\Installer\*; `
    Remove-Item -Force WindowsHosting.exe

RUN setx /M PATH $($Env:PATH + ';' + $Env:ProgramFiles + '\dotnet')
# Enable detection of running in a container
ENV DOTNET_RUNNING_IN_CONTAINER=true

# Configure IIS website
RUN Remove-Website -Name 'Default Web Site'; `
    Set-ItemProperty IIS:\AppPools\DefaultAppPool -Name managedRuntimeVersion -Value ''; `
    Set-ItemProperty IIS:\AppPools\DefaultAppPool -Name enable32BitAppOnWin64 -Value 0; `
    Set-ItemProperty IIS:\AppPools\DefaultAppPool -Name processModel -value @{identitytype='ApplicationPoolIdentity'}; `
    New-Website -Name 'webapp' `
    -Port 80 -PhysicalPath 'C:\webapp' `
    -ApplicationPool 'DefaultAppPool' -force;

RUN Import-Module IISAdministration; `
    Start-IISCommitDelay; `
    (Get-IISConfigSection -SectionPath 'system.webServer/security/authentication/windowsAuthentication').Attributes['enabled'].value = $true; `
    (Get-IISConfigSection -SectionPath 'system.webServer/security/authentication/anonymousAuthentication').Attributes['enabled'].value = $true; `
    Stop-IISCommitDelay;


# Create a directory for the webapp and copy it
RUN mkdir c:\webapp
COPY .\output\ c:\webapp


SHELL ["cmd", "/S", "/C"] 

## Configure LogMonitor
WORKDIR /LogMonitor
COPY LogMonitorConfig.json .
RUN powershell.exe -command wget -uri https://github.com/microsoft/windows-container-tools/releases/download/v1.1/LogMonitor.exe -outfile LogMonitor.exe
# Change the startup type of the IIS service from Automatic to Manual
RUN sc config w3svc start=demand
# Enable ETW logging for the Web Site on IIS
RUN c:\windows\system32\inetsrv\appcmd.exe set config -section:system.applicationHost/sites /"[name='webapp'].logFile.logTargetW3C:"File,ETW"" /commit:apphost
EXPOSE 80

# Start "C:\LogMonitor\LogMonitor.exe C:\ServiceMonitor.exe w3svc"
ENTRYPOINT ["C:\\LogMonitor\\LogMonitor.exe", "C:\\ServiceMonitor.exe", "w3svc"]