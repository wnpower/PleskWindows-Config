# Script de instalación de Plesk Onyx en Windows Server

## Lo que hace

 1. Instala Plesk Onyx Windows con los paquetes recomendados
 2. Configura idioma a Español
 3. Configura valores recomendados de visual y de permisos básicos (dominios prohibidos, solapamiento de subdominios, etc)
 4. Configura el Firewall de Windows con reglas básicas de salida
 5. Mailserver: configura AntiSPAM, listas negras y máximo de envíos por hora
 6. Configura todos los php.ini con los valores recomendados
 7. Configura tarea programada de backup diario

## Modo de uso

 1. Abrir una consola Powershell y ejecutar:

```
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force
$Url = "https://raw.githubusercontent.com/wnpower/PleskWindows-Config/master/install_pleskonyx.ps1"
$Output = "C:\Windows\Temp\install_pleskonyx.ps1"
$WebClient = New-Object System.Net.WebClient
$WebClient.DownloadFile( $url , $Output)
Invoke-Expression $Output
```
