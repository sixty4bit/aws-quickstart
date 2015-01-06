param(
    [string]$Instance,
    [string]$Region,
    [string]$ELBFqdn
)

$guid = (Get-EC2Instance -Filter @{name='tag:Name';values=$Instance} -Region $Region)[0].Instances.tags.where{$_.key -eq 'guid'}.value

Configuration SetPullMode {
    Node $env:COMPUTERNAME {
        LocalConfigurationManager {
            ConfigurationMode = 'ApplyAndAutoCorrect'
            ConfigurationID = $guid
            CertificateId = (Get-ChildItem Cert:\LocalMachine\My | Where-Object { $_.Subject -eq "CN=$ELBFqdn" })[0].Thumbprint
            RefreshMode = 'Pull'
            ConfigurationModeFrequencyMins = 30
            RefreshFrequencyMins = 15
            RebootNodeIfNeeded = $true
            DownloadManagerName = 'WebDownloadManager'
            DownloadManagerCustomData = @{
                ServerUrl = "https://$($ELBFqdn):8080/PSDSCPullServer.svc"
                AllowUnsecureConnection = 'false'
            }
        }
    }
}

SetPullMode
Set-DscLocalConfigurationManager -ComputerName $env:COMPUTERNAME -Path .\SetPullMode

