function Install-Terraform() {
    [CmdletBinding(DefaultParameterSetName = 'Version')]
    param
    (
        [Parameter(ParameterSetName = 'Latest', Mandatory = $true)]
        [Parameter(ParameterSetName = 'Version', Mandatory = $true)]
        [String]
        $SaveToPath,

        [Parameter(ParameterSetName = 'Version', Mandatory = $true)]
        [String]
        $Version,

        [Parameter(ParameterSetName = 'Latest')]
        [Switch]
        $Latest
    )

    try {
        Write-Output "Installing Terraform..."

        if ($PSCmdlet.ParameterSetName -eq 'Version') {
            $downloadVersion = $Version
        }
        else {
            $releasesUrl = 'https://api.github.com/repos/hashicorp/terraform/releases'
            $releases = Invoke-RestMethod -Method Get -UseBasicParsing -Uri $releasesUrl
            $downloadVersion = $releases.Where({ !$_.prerelease })[0].name.trim('v')
        }

        $terraformFile = "terraform_${downloadVersion}_windows_amd64.zip"
        $terraformURL = "https://releases.hashicorp.com/terraform/${downloadVersion}/${terraformFile}"

        $download = Invoke-WebRequest -UseBasicParsing -Uri $terraformURL -DisableKeepAlive -OutFile "${env:Temp}\${terraformFile}" -ErrorAction SilentlyContinue -PassThru

        if (($download.StatusCode -eq 200) -and (Test-Path "${env:Temp}\${terraformFile}")) {
            # If SaveToPath does not exist, create it
            if (-not (Test-Path -Path $SaveToPath)) {
                $null = New-Item -Path $SaveToPath -ItemType Directory -Force
            }

            # Unblock File
            Unblock-File "${env:Temp}\${terraformFile}"

            # Unpack archive
            Start-Sleep -Seconds 10
            Expand-Archive -Path "${env:Temp}\${terraformFile}" -DestinationPath $SaveToPath -Force

            # Clean up temp folder
            Remove-Item -Path "${env:Temp}\${terraformFile}" -Force

            # Set up environment variable
            $path = [Environment]::GetEnvironmentVariable('Path', 'User')
            [Environment]::SetEnvironmentVariable('PATH', "${path};${SaveToPath}", 'User')

            Write-Output "Terraform installed."
        } 
        else {
            Write-Error "Error while downloading Terraform."
        }
    }
    catch {
        Write-Error $_
    }
}

function Install-AzCLI() {
    try {
        Write-Output "Installing az CLI..."

        $azCLIFile = "${env:Temp}\AzureCLI.msi"

        Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile $azCLIFile

        if (Test-Path $azCLIFile) {
            Start-Process msiexec.exe -Wait -ArgumentList "/I $azCLIFile /quiet"
            Remove-Item $azCLIFile
            Write-Output "az CLI installed."
        }
        else {
            Write-Error "Could not download az CLI."
        }
    }
    catch {
        Write-Error $_
    }
}


Install-AzCLI
Install-Terraform -SaveToPath C:\Terraform -Latest