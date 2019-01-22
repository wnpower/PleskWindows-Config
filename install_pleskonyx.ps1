$ScriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$ISVM = (Get-WmiObject -Class Win32_ComputerSystem).Model | Select-String -Pattern "KVM|Virtual" -Quiet

echo "Descargando instalador de Plesk..."
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force
$Url = "https://installer-win.plesk.com/plesk-installer.exe"
$Output = "C:\Windows\Temp\plesk-installer.exe"
$WebClient = New-Object System.Net.WebClient
$WebClient.DownloadFile( $url , $Output)

echo "Ejecutando instalador de Plesk..."
&"$Output" --select-product-id=panel --select-release-latest `
--install-component common `
--install-component panel `
--install-component awstats `
--install-component mailenable `
--install-component msdns `
--install-component spamassassin `
--install-component mysql-odbc `
--install-component mylittleadmin `
--install-component webalizer `
--install-component mssql2016 `
--install-component webmail `
--install-component plesk-urlprotection `
--install-component webdeploy `
--install-component urlrewrite `
--install-component health-monitoring `
--install-component gitforwindows `
--install-component plesk-migration-manager `
--install-component msodbcsql11 `
--install-component msodbcsql13 `
--install-component msodbcsql17 `
--install-component mysql57-client `
--install-component mysql-odbc53 `
--install-component modsecurity `
--install-component php54 `
--install-component php55 `
--install-component php56 `
--install-component php70 `
--install-component php71 `
--install-component php72 `
--install-component webdav `
--install-component dotnetcoreruntime `
--install-component aspnetcore `
--install-component appinit `
--install-component http-dynamic-compression `
--install-component cloudflare `
--install-component git `
--install-component letsencrypt

$AdminPassword = Read-Host -Prompt 'Password usuario "Administrator" '

echo "Configuración inicial Plesk..."
& 'C:\Program Files (x86)\Plesk\bin\init_conf.exe' -p -passwd "$AdminPassword" -license_agreed true -admin_info_not_required true

echo "Instalando licencia..."
Add-Content -Path 'C:\Program Files (x86)\Plesk\admin\conf\panel.ini' -Value "[license]"
Add-Content -Path 'C:\Program Files (x86)\Plesk\admin\conf\panel.ini' -Value "fileUpload = on"

net stop plesksrv
net start plesksrv

Write-Host -NoNewLine 'En este punto instalá la licencia de Plesk (XML o key) usando el panel web y luego apretá enter...';
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');

#& 'C:\Program Files (x86)\Plesk\bin\license.exe' -i $License

echo "Configurando Plesk..."

echo "Configurando idioma..."
& 'C:\Program Files (x86)\Plesk\bin\locales.exe' --set-default es-ES

echo "Configurando links GUI..."
& 'C:\Program Files (x86)\Plesk\bin\panel_gui.exe' -p -domain_registration true -cert_purchasing true

echo "Configurando servidor..."
& 'C:\Program Files (x86)\Plesk\bin\server_pref.exe' --update -include-remote-databases false -forbid-subscription-rename true -forbid-create-dns-subzone true -min_password_strength strong
& 'C:\Program Files (x86)\Plesk\bin\admin.exe' --update -multiple-sessions true
& 'C:\Program Files (x86)\Plesk\bin\domain_restriction.exe' --enable
& 'C:\Program Files (x86)\Plesk\bin\poweruser.exe' --off

echo "Configurando IIS Pools..."
& 'C:\Program Files (x86)\Plesk\bin\server_pref.exe' --set-iis-app-pool-settings -cpu-usage-state true -cpu-usage-value 20 -cpu-usage-action Throttle

echo "Configurando Firewall..."
if([System.IO.File]::Exists("$Env:Programfiles (x86)\Mail Enable\Bin64\MESMTPC.exe")){
	netsh advfirewall firewall add rule name="MESMTPC.exe (MailEnable SMTP Connector)" dir=out program="%ProgramFiles% (x86)\Mail Enable\Bin64\MESMTPC.exe" protocol=tcp  action=allow

}
if([System.IO.File]::Exists("$Env:Programfiles (x86)\Plesk\Mail Servers\Mail Enable\Bin64\MESMTPC.exe")){
        netsh advfirewall firewall add rule name="MESMTPC.exe (MailEnable SMTP Connector)" dir=out program="%ProgramFiles% (x86)\Plesk\Mail Servers\Mail Enable\Bin64\MESMTPC.exe" protocol=tcp  action=allow
}

netsh advfirewall firewall add rule name="Allow OUT TCP" dir=out remoteport="20,21,37,43,53,80,110,113,443,873,3306,1433,6363,5224,1688" protocol=tcp  action=allow
netsh advfirewall firewall add rule name="Allow OUT UDP" dir=out remoteport="53" protocol=udp  action=allow
netsh advfirewall firewall add rule name="Allow OUT ICMP" protocol=icmpv4:any,any dir=out action=allow
netsh advfirewall set allprofiles firewallpolicy blockinbound,blockoutbound

echo "Configurando mail..."
& 'C:\Program Files (x86)\Plesk\bin\mailserver.exe' --enable-outgoing-antispam
& 'C:\Program Files (x86)\Plesk\bin\mailserver.exe' --set-outgoing-messages-subscription-limit 200
& 'C:\Program Files (x86)\Plesk\bin\mailserver.exe' --set-outgoing-messages-domain-limit 200
& 'C:\Program Files (x86)\Plesk\bin\mailserver.exe' --set-maps-zone "zen.spamhaus.org,bl.spamcop.net,b.barracudacentral.org"
& 'C:\Program Files (x86)\Plesk\bin\mailserver.exe' --set-maps-status true
& 'C:\Program Files (x86)\Plesk\bin\spamassassin.exe' --update-server -status true

echo "Configurando php.ini..."
Get-ChildItem "C:\Program Files (x86)\Plesk\Additional\" -Recurse -Filter "php.ini" |
Foreach-Object {
	echo "Procesando "$_.FullName
    $content = Get-Content $_.FullName
	$content | %{$_ -replace "^memory_limit.*","memory_limit = 1024M"} | Set-Content $_.FullName
	$content = Get-Content $_.FullName
	$content | %{$_ -replace "^enable_dl.*","enable_dl = Off"} | Set-Content $_.FullName
	$content = Get-Content $_.FullName
	$content | %{$_ -replace "^expose_php.*","expose_php = Off"} | Set-Content $_.FullName
	$content = Get-Content $_.FullName
	$content | %{$_ -replace "^disable_functions.*","disable_functions = apache_get_modules,apache_get_version,apache_getenv,apache_note,apache_setenv,disk_free_space,diskfreespace,dl,exec,highlight_file,ini_alter,ini_restore,openlog,passthru,phpinfo,popen,posix_getpwuid,proc_close,proc_get_status,proc_nice,proc_open,proc_terminate,shell_exec,show_source,symlink,system,eval,debug_zval_dump"} | Set-Content $_.FullName
	$content = Get-Content $_.FullName
	$content | %{$_ -replace "^upload_max_filesize.*","upload_max_filesize = 16M"} | Set-Content $_.FullName
	$content = Get-Content $_.FullName
	$content | %{$_ -replace "^post_max_size.*","post_max_size = 16M"} | Set-Content $_.FullName
	$content = Get-Content $_.FullName
	$content | %{$_ -replace "^date.timezone.*",'date.timezone = "America/Argentina/Buenos_Aires"'} | Set-Content $_.FullName
	$content = Get-Content $_.FullName
	$content | %{$_ -replace "^allow_url_fopen.*","allow_url_fopen = On"} | Set-Content $_.FullName
	$content = Get-Content $_.FullName
	$content | %{$_ -replace "^max_execution_time.*","max_execution_time = 120"} | Set-Content $_.FullName
	$content = Get-Content $_.FullName
	$content | %{$_ -replace "^max_input_time.*","max_input_time = 120"} | Set-Content $_.FullName
	$content = Get-Content $_.FullName
	$content | %{$_ -replace "^max_input_vars.*","max_input_vars = 2000"} | Set-Content $_.FullName
	$content = Get-Content $_.FullName
	$content | %{$_ -replace "^display_errors.*","display_errors = On"} | Set-Content $_.FullName
	$content = Get-Content $_.FullName
	$content | %{$_ -replace "^error_reporting.*","error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT"} | Set-Content $_.FullName
}

echo "Configurando timezone Horde Webmail..."
$hordephpini = "C:\Program Files (x86)\Plesk\Webmail\horde\conf\php.ini"
$content = Get-Content $hordephpini
$content | %{$_ -replace "^date.timezone.*",'date.timezone = "America/Argentina/Buenos_Aires"'} | Set-Content $hordephpini

echo "Configurando Backup..."
echo "Descargando tarea programada..."
$Url = "https://raw.githubusercontent.com/wnpower/PleskWindows-Config/master/Plesk%20Scheduler%20Task%20%23Domain%20Backup%20Scheduler%201.xml"
$Output = "C:\Windows\Temp\Plesk Scheduler Task #Domain Backup Scheduler 1.xml"
$WebClient = New-Object System.Net.WebClient
$WebClient.DownloadFile( $url , $Output)

& 'C:\Program Files (x86)\Plesk\bin\plesk.exe' "db" "INSERT INTO backupsscheduled VALUES (1,1,'server','local','2018-07-18 10:38:16',86400,'true','false',4,'','',0,'false','true',0,'23:00:00','backup_content_all_at_domain',604800,1,1,0,NULL);"
Register-ScheduledTask -Xml (get-content "C:\Windows\Temp\Plesk Scheduler Task #Domain Backup Scheduler 1.xml" | out-string) -TaskName 'Plesk Scheduler Task #Domain Backup Scheduler 1' -User "SYSTEM"

echo "Configurando SQL Server..."
echo "Abriendo puerto 1433 (SQL Express)..."
Import-Module "sqlps"

$MachineObject = new-object ('Microsoft.SqlServer.Management.Smo.WMI.ManagedComputer') .

$serverinstance = $MachineObject | select-object -expand ServerInstances | select-object -expand Name
$ProtocolUri = "ManagedComputer[@Name='" + (get-item env:computername).Value + "']/ServerInstance[@Name='$serverinstance']/ServerProtocol"

$tcp = $MachineObject.getsmoobject($ProtocolUri + "[@Name='Tcp']")
$np = $MachineObject.getsmoobject($ProtocolUri + "[@Name='Np']")
$sm = $MachineObject.getsmoobject($ProtocolUri + "[@Name='Sm']")

$np.IsEnabled = $true
$np.alter()
$tcp.IsEnabled = $true
$tcp.alter()

$MachineObject.getsmoobject($tcp.urn.Value + "/IPAddress[@Name='IPAll']").IPAddressProperties[1].Value = "1433"
$tcp.alter()

Restart-Service -displayname "*MSSQLSERVER*" -Exclude "*Agent*"

if ($ISVM) {
        echo "VM detectada, desactivando Health Monitor/Notifier porque consume mucho y se cuelga..."
	Set-Service ParallelsHealthMonitor -StartupType Disabled
	Set-Service ParallelsHealthNotifier -StartupType Disabled

	Stop-Service ParallelsHealthMonitor
	Stop-Service ParallelsHealthNotifier
}

echo "Finalizado!"
