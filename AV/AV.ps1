##Deshabilitar Av y firewall
Set-Service -Name "WinDefend" -StartupType Disabled
Stop-Service -Name "WinDefend"
Set-Service -Name "MpsSvc" -StartupType Disabled
Stop-Service -Name "MpsSvc"