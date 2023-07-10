<# FYPWebNonProd DSC configuration file
Date:		29/09/2022 
Author:		Mike Andrews
Change:		Removal of Kerberos Realms

#>

#command to create config file
configuration FYPWebProd {

    Import-DscResource -ModuleName CertificateDsc
    Import-DscResource -ModuleName ComputerManagementDsc
    Import-DscResource -Module NetworkingDsc

    # Wild Card Credentials are obtained from the Automation account Credentials not the keyvault for Certificates

    $filesharecreds = Get-AutomationPSCredential -Name InfraFileShareCreds
    $agentfilesharecreds = Get-AutomationPSCredential -Name AgentFileShareCreds
    $MPSMED = Get-AutomationPSCredential -Name MPSMED
    $MPSDEN = Get-AutomationPSCredential -Name MPSDEN
    $LanPass = Get-AutomationPSCredential -Name LanPass

    #specify target server, node 1 will consume the below config
    node FYPWebServer {

        LocalConfigurationManager { 
			
            # This is false by default
            RebootNodeIfNeeded = $false
        } 

        #Install web server windows feature
        windowsfeature IIS {

            name   = "web-server"
            Ensure = "Present"
        }
	
        #Install web server windows feature
        windowsfeature IISManagementConsole {
            name   = "Web-Mgmt-Console"
            Ensure = "Present"
        }
		
        #Install web server windows feature
        windowsfeature IISManagementService {
            name   = "Web-Mgmt-Service"
            Ensure = "Present"
        }

        #Get required installers from file share
        file installers {
            Ensure          = "Present"
            Type            = "directory"
            Recurse         = $true
            Matchsource     = $true
            sourcepath      = ""
            destinationpath = ""
            credential      = $filesharecreds
        }

        file agent {
            Ensure          = "Present"
            Type            = "directory"
            Recurse         = $true
            Matchsource     = $true
            sourcepath      = ""
            destinationpath = ""
            credential      = $agentfilesharecreds
        }

		
        # *.n.org
        PfxImport dev {
            Thumbprint = ''
            Path       = ''
            Location   = 'LocalMachine'
            Store      = 'My'
            Exportable = $false
            Credential = $MPSDEN
            Ensure     = 'present'
        }

        # *n.org
        PfxImport test {
            Thumbprint = ''
            Path       = ''
            Location   = 'LocalMachine'
            Store      = 'My'
            Exportable = $false
            Credential = $MPSMED
            Ensure     = 'present'
        }

        RemoteDesktopAdmin RemoteDesktopSettings {
            IsSingleInstance   = 'yes'
            Ensure             = 'Present'
            UserAuthentication = 'NonSecure'
        }

        User LanSweeper {
            Ensure   = "Present"
            UserName = ""
            Password = $LanPass
        }

        Group Admin {
            GroupName        = 'Administrators'
            Ensure           = 'Present'
            MembersToInclude = ''
            DependsOn        = "[User]LanSweeper"
        }

        NetConnectionProfile SetPrivate {
            InterfaceAlias  = 'Ethernet'
            NetworkCategory = 'Private'
        }

        FirewallProfile ConfigurePrivateFirewallProfile {
            Name    = 'Private'
            Enabled = 'False'
        }

        #Install .net core hosting
        package InstallDotNetCoreHosting {
            path      = "c:\temp\mps\dotnet-hosting-6.0.9-win.exe"
            ensure    = "Present"
            Arguments = "/q /norestart"
            Name      = "DotNetCore"
            ProductID = "{C30ABA3F-32C0-43D1-B3B8-9AEFD58A15D9}" 
        }

    } #node config

} #configuration