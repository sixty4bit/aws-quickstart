param(
    [string]$Instance,
    [string]$Region
    )

$guid = (Get-EC2Instance -Filter @{name='tag:Name';values=$Instance} -Region $Region)[0].Instances.tags.where{$_.key -eq 'guid'}.value
$PullServer = (Get-ELBLoadBalancer -Region $Region)[0].DNSName

Configuration SetPullMode {
    Node $env:COMPUTERNAME {
        LocalConfigurationManager {
            ConfigurationMode = 'ApplyAndAutoCorrect'
            ConfigurationID = $guid
            CertificateId = (Get-ChildItem Cert:\LocalMachine\My | Where-Object { $_.Subject -eq "CN=$PullServer" })[0].Thumbprint
            RefreshMode = 'Pull'
            ConfigurationModeFrequencyMins = 30
            RefreshFrequencyMins = 15
            RebootNodeIfNeeded = $true
            DownloadManagerName = 'WebDownloadManager'
            DownloadManagerCustomData = @{
                ServerUrl = "https://$($PullServer):8080/PSDSCPullServer.svc"
                AllowUnsecureConnection = 'false'
            }
        }
    }
}

SetPullMode
Set-DscLocalConfigurationManager -ComputerName $env:COMPUTERNAME -Path .\SetPullMode

