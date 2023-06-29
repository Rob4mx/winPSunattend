Start-Transcript -path $HOME\Desktop\reporte.txt -append

Write-Host @"
    ---------------------------------------------------
    | Instalacion desatendida de drivers y programas. |
    | Script v0.67 basado en PowerShell, de Rob.      |
    ---------------------------------------------------
"@

# ------------------------------------------------------------------------------------------------------ Variables de trabajo
$RND = Get-Random -Maximum 9
$CHIPSET = $env:PROCESSOR_IDENTIFIER[-12..-1] -join ''
$DRIVE = $PSScriptRoot.Substring(0,2)
$MOBO = wmic baseboard get manufacturer,product
$MOBO = $MOBO[2]

# ------------------------------------------------------------------------------------------------------ Wallpaper
Write-Host '---------- Copiando fondo de pantalla ----------'
try {
    copy $DRIVE\FONDO_XT\BackgroundXtreme$RND.jpg $HOME\Pictures -ErrorAction Stop
    Write-Host '    Listo'
} catch {
    Write-Host '    ERROR: Verifique los archivos de la carpeta FONDO_XT' -BackgroundColor 'Red'
}
Write-Host ''

# ------------------------------------------------------------------------------------------------------ MOBO chipset & otros
Write-Host '---------- Tarjeta madre ----------'
Write-Host $MOBO

if ($CHIPSET -eq 'GenuineIntel') {
# https://www.intel.la/content/www/xl/es/download/19347/chipset-inf-utility.html
    Write-Host '    Detectado Chipset Intel. Instalando controladores...'
    try {
        Start-Process -Wait $DRIVE\DRIVERS\Intel\Chipset\SetupChipset.exe -ArgumentList "-s -norestart" -ErrorAction Stop
        pnputil /add-driver $DRIVE\DRIVERS\Intel\Chipset\*.inf /subdirs /install
        Write-Host '    Instalacion completada.'
    } catch {
        Write-Host '    ERROR: Verificar archivos de instalacion en la carpeta DRIVERS\Intel\Chipset\SetupChipset.exe' -BackgroundColor 'Red'
        Write-Host '    ¡Instalacion abortada!' -BackgroundColor 'Red'
    }
}
if ($CHIPSET -eq 'AuthenticAMD'){
# https://www.amd.com/es/support/chipsets/amd-socket-am5/x670e
    Write-Host '    Detectado Chipset AMD. Instalando controladores...'
    try {
        Start-Process -Wait $DRIVE\DRIVERS\AMD\Chipset\amd_chipset_software_5.05.16.529.exe -ArgumentList "/s /v/qn" -ErrorAction Stop
        pnputil /add-driver $DRIVE\DRIVERS\AMD\Chipset\*.inf /subdirs /install
        Write-Host '    Instalacion completada.'
    } catch {
        Write-Host '    ERROR: Verificar archivos de instalacion en la carpeta DRIVERS\AMD\Chipset\amd_chipset_software_5.05.16.529.exe' -BackgroundColor 'Red'
        Write-Host '    ¡Instalacion abortada!' -BackgroundColor 'Red'
    }
}
# Ethernet/WiFi
pnputil /add-driver $DRIVE\DRIVERS\Realtek\*.inf /subdirs /install
pnputil /add-driver $DRIVE\DRIVERS\MediaTek\*.inf /subdirs /install

Write-Host ''

# ------------------------------------------------------------------------------------------------------- GPU
Write-Host '---------- Tarjeta de video ----------'
# Para Intel se usa el archivo "iigd_dch.inf" para cotejar con el hardware instalado y decidir el driver a instalar. Se puede descargar el más reciente en www.techpowerup.com
$GPU_Intel = pnputil /enum-devices /class Display
$GPU_Intel = $GPU_Intel -like "*PCI\VEN_8086*"
if ($GPU_Intel) {
    Write-Host "    Intel Graphics encontrado. Instalando controlador..." $GPU_Intel
    Start-Process -Wait $DRIVE\DRIVERS\Intel\Video_6+\gfx_win_101.3790_101.2114.exe -ArgumentList "-s"
}
 
# Para AMD se usa una lista generada con el script "generador_lista_hardware_radeon.ps1" utilizando el archivo INF del paquete de controladores de pantalla. Se puede descargar el más reciente en www.techpowerup.com
# Debe generarse un archivo tanto para el paquete Estándar como para el paquete Legacy
$INF_AMD = Get-Content $DRIVE\DRIVERS\AMD\Radeon\Hardware_Radeon.txt
$INF_AMD_Legacy = Get-Content $DRIVE\DRIVERS\AMD\Radeon-Legacy\Hardware_Radeon.txt
$GPU_AMD = pnputil /enum-devices /class Display
$GPU_AMD = $GPU_AMD -like "*PCI\VEN_1002*"
if ($GPU_AMD) {
    $GPU_AMD = $GPU_AMD.Substring(37,17)
    if ($INF_AMD -like "*$GPU_AMD*") {
        Write-Host "    AMD Radeon encontrado. Instalando controlador..." $GPU_AMD
        Start-Process -Wait $DRIVE\DRIVERS\AMD\Radeon\whql-amd-software-adrenalin-edition-23.5.2-win10-win11-may31.exe -ArgumentList "-install"
        $WshShell = New-Object -comObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut("$HOME\Desktop\AMD Software Adrenalin Edition.lnk")
        $Shortcut.TargetPath = "C:\Program Files\AMD\CNext\CNext\RadeonSoftware.exe"
        $Shortcut.Save()
    } elseif ($INF_AMD_Legacy -like "*$GPU_AMD*") {
        Write-Host "    AMD Radeon Legacy encontrado. Instalando controlador..." $GPU_AMD
        Start-Process -Wait $DRIVE\DRIVERS\AMD\Radeon-Legacy\setup.exe -ArgumentList '-y -o"C:\AMD\LegacyGraphics"'
        Start-Process -Wait C:\AMD\LegacyGraphics\Setup.exe -ArgumentList "-install"
    }
}

# Para NVIDIA se usa el archivo ListDevices.txt extraído del paquete de controladores. Se puede descargar el más reciente en www.techpowerup.com
$INF_NVIDIA = Get-Content $DRIVE\DRIVERS\NVIDIA\ListDevices.txt
$GPU_NVIDIA = pnputil /enum-devices /class Display
$GPU_NVIDIA = $GPU_NVIDIA -like "*PCI\VEN_10DE*"
if ($GPU_NVIDIA) {
    $GPU_NVIDIA = $GPU_NVIDIA.Substring(46,8)
    if ($INF_NVIDIA -like "*$GPU_NVIDIA*") {
        Write-Host "    NVIDIA GeForce encontrado. Instalando controlador..." $GPU_NVIDIA
        Start-Process -Wait $DRIVE\DRIVERS\NVIDIA\536.23-desktop-win10-win11-64bit-international-dch-whql.exe.exe -ArgumentList "/s /noreboot"
    }
}
Write-Host ''

# --------------------------------------------------------------------------------------------------------- Realtek Audio
Write-Host '---------- Instalando controladores de audio compatibles... ----------'
try {
    Start-Process -Wait $DRIVE\DRIVERS\Realtek\DM-034\HD825E.exe -ArgumentList "/s" -ErrorAction Stop
    Write-Host '    Listo'
} catch {
    Write-Host '    ERROR: Verificar archivos de instalacion en la carpeta DRIVERS\Realtek\DM-034' -BackgroundColor 'Red'
}
Write-Host ''

# --------------------------------------------------------------------------------------------------------- MS Office
Write-Host '---------- Instalando Office... ----------'
try {
    Start-Process -Wait $DRIVE\OFFICE_2013\setup.exe -ErrorAction Stop
    $WshShell = New-Object -comObject WScript.Shell
    New-Item -Path "$HOME\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Microsoft Office 2013" -ItemType Directory
    $Shortcut = $WshShell.CreateShortcut("$HOME\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Microsoft Office 2013\Word 2013.lnk")
    $Shortcut.TargetPath = "C:\Program Files (x86)\Microsoft Office\Office15\WINWORD.EXE"
    $Shortcut.Save()

    $Shortcut = $WshShell.CreateShortcut("$HOME\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Microsoft Office 2013\Excel 2013.lnk")
    $Shortcut.TargetPath = "C:\Program Files (x86)\Microsoft Office\Office15\EXCEL.EXE"
    $Shortcut.Save()

    $Shortcut = $WshShell.CreateShortcut("$HOME\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Microsoft Office 2013\PowerPoint 2013.lnk")
    $Shortcut.TargetPath = "C:\Program Files (x86)\Microsoft Office\Office15\POWERPNT.EXE"
    $Shortcut.Save()
    Write-Host '    Listo'
} catch {
    Write-Host '    ERROR: Verificar archivos de instalacion de Office en la carpeta OFFICE_2013' -BackgroundColor 'Red'
}
Write-Host ''

# --------------------------------------------------------------------------------------------------------- Activadores
Write-Host '---------- Pre-activando Windows... ----------'
# Agradecimiento al paquete "MAS v1.6" del usuario "massgravel" de GitHub (https://github.com/massgravel/Microsoft-Activation-Scripts)
try {
    Start-Process -Wait $DRIVE\ACTIVADOR\Separate-Files-Version\HWID-KMS38_Activation\KMS38_Activation.cmd -ArgumentList "/a"
    Start-Process -Wait $DRIVE\ACTIVADOR\Separate-Files-Version\HWID-KMS38_Activation\HWID_Activation.cmd -ArgumentList "/a"
    Write-Host '    Listo'
} catch {
    Write-Host '    ERROR: Verificar archivos de instalacion de la carpeta ACTIVADOR' -BackgroundColor 'Red'
}
Write-Host ''

Write-Host '---------- Pre-activando Office... ----------'
# Agradecimiento al paquete "MAS v1.6" del usuario "massgravel" de GitHub (https://github.com/massgravel/Microsoft-Activation-Scripts)
try {
    Start-Process -Wait $DRIVE\ACTIVADOR\Separate-Files-Version\Online_KMS_Activation\Activate.cmd -ArgumentList "/wo"
    Start-Process -Wait $DRIVE\ACTIVADOR\Separate-Files-Version\Online_KMS_Activation\Activate.cmd -ArgumentList "/rat"
    Write-Host '    Listo'
} catch {
    Write-Host '    ERROR: Verificar archivos de instalacion de la carpeta ACTIVADOR' -BackgroundColor 'Red'
}
Write-Host ''

# ---------------------------------------------------------------------------------------------------------- Wallpaper
Write-Host '---------- Estableciendo fondo de pantalla... ----------'
Set-ItemProperty -path 'HKCU:\Control Panel\Desktop\' -name WallPaper -value $HOME\Pictures\BackgroundXtreme$RND.jpg
for ($i=0; $i -le 20; $i++) {
    rundll32.exe user32.dll,UpdatePerUserSystemParameters ,1 ,True
}
Write-Host '    Listo'
Write-Host ''

# ---------------------------------------------------------------------------------------------------------- CrystalDiskInfo
Write-Host '---------- Ejecutando CrystalDiskInfo... ----------'
try {
    Start-Process -Wait $DRIVE\HERRAMIENTAS\CrystalDiskInfo\DiskInfo64.exe -ArgumentList "/CopyExit"
    Move-Item $DRIVE\HERRAMIENTAS\CrystalDiskInfo\DiskInfo.txt $HOME\Desktop
    $Crystal = Get-Content $HOME\Desktop\DiskInfo.txt
    $Crystal = $Crystal -match "Health Status :"
    $Crystal | Out-File $HOME\Desktop\Crystal.txt
    Remove-Item $HOME\Desktop\DiskInfo.txt
    Remove-Item $DRIVE\HERRAMIENTAS\CrystalDiskInfo\Smart -Recurse
    Write-Host '    Creado archivo de reporte en el escritorio.'
} catch {
    Write-Host '    ERROR: Verificar archivos de instalacion de CystalDiskInfo en la carpeta HERRAMIENTAS\CrystalDiskInfo' -BackgroundColor 'Red'
}
Write-Host ''

# ------------------------------------------------------------------------------------------------------ Cambio de nombre en Red
Write-Host '---------- Cambiando de nombre en red... ----------'
$RND = Get-Random -Maximum 9999
Rename-Computer -NewName "User$RND-PC"
Write-Host '    Listo'
Write-Host ''

# ------------------------------------------------------------------------------------------------------- Specs
$CPU_Name = Get-WmiObject Win32_Processor | Select-Object -ExpandProperty Name
$RAM_Capacity = (Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property capacity -Sum).sum /1gb
$RAM_Speed = (Get-WmiObject Win32_PhysicalMemory | Select-Object -ExpandProperty Speed)[0]
$RAM_Type = (Get-WmiObject Win32_PhysicalMemory | Select-Object -ExpandProperty SMBIOSMemoryType)[0]
$Disk0_type = (Get-PhysicalDisk | Select-Object -ExpandProperty MediaType)[0]
$Disk0_size = (Get-PhysicalDisk | Select-Object -ExpandProperty Size)[0]/1000000000
$Disk0_size = [math]::Round($Disk0_size)
$Disk1_type = (Get-PhysicalDisk | Select-Object -ExpandProperty MediaType)[1]
$Disk1_size = (Get-PhysicalDisk | Select-Object -ExpandProperty Size)[1]/1000000000
$Disk1_size = [math]::Round($Disk1_size)
$Motherboard = (wmic baseboard get manufacturer,product)[2]
$Graphics_card = Get-WmiObject win32_VideoController | Select-Object -ExpandProperty Name

if ($RAM_Type -eq 24) {
    $RAM_Type = "DDR3"
} elseif ($RAM_Type -eq 26) {
    $RAM_Type = "DDR4"
} elseif ($RAM_Type -eq 28) {
    $RAM_Type = "DDR5"
}

echo $CPU_Name | Out-File -FilePath $HOME\Desktop\specs.txt
echo $RAM_Capacity" GB "$RAM_Type" @ "$RAM_Speed" MHz" | Out-File -FilePath $HOME\Desktop\specs.txt -Append
echo "$Disk0_type $Disk0_size GiB" | Out-File -FilePath $HOME\Desktop\specs.txt -Append
echo "$Disk1_type $Disk1_size GiB" | Out-File -FilePath $HOME\Desktop\specs.txt -Append
echo $Motherboard | Out-File -FilePath $HOME\Desktop\specs.txt -Append
echo $Graphics_card | Out-File -FilePath $HOME\Desktop\specs.txt -Append
# ------------------------------------------------------------------------------------------------------- END
Stop-Transcript
Restart-Computer
