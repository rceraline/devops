param (
    [string]$URL,
    [string]$PAT,
    [string]$POOL,
    [string]$AGENT
)

Write-Host "start"

if (test-path "c:\agent")
{
    Remove-Item -Path "c:\agent" -Force -Confirm:$false -Recurse
}

New-Item -ItemType Directory -Force -Path "c:\agent"
Set-Location "c:\agent"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$wr = Invoke-WebRequest https://api.github.com/repos/Microsoft/azure-pipelines-agent/releases/latest -UseBasicParsing
$tag = ($wr | ConvertFrom-Json)[0].tag_name
$tag = $tag.Substring(1)

Write-Host "$tag is the latest version"
$url = "https://vstsagentpackage.azureedge.net/agent/$tag/vsts-agent-win-x64-$tag.zip"

Invoke-WebRequest $url -Out agent.zip -UseBasicParsing
Expand-Archive -Path agent.zip -DestinationPath $PWD
.\config.cmd --unattended --url $URL --auth pat --token $PAT --pool $POOL --agent $AGENT --acceptTeeEula --runAsService

exit 0