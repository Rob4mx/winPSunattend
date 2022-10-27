Start-Transcript -path $HOME\Desktop\reporte.txt -append

Write-Host @"

             ,----------------,              ,---------,
        ,-----------------------,          ,"        ,"|
      ,"                      ,"|        ,"        ,"  |
     +-----------------------+  |      ,"        ,"    |
     |   -----------------.  |  |     +---------+      |
     |  |                 |  |  |     | -==----'|      |          %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
     |  |  No te veo      |  |  |     |         |      |          % Instalacion desatendida de drivers y programas. %
     |  |  :(             |  |  |/----|'---=    |      |          % Script v0.6 basado en PowerShell, de Rob.       %
     |  |  <3             |  |  |   ,/|==== ooo |      ;          %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
     |  |                 |  |  |  // |(((( [33]|    ,"
     |  '-----------------'  |," .;'| |((((     |  ,"
     +-----------------------+  ;;  | |         |,"     -Kevin Lam-
        /_)______________(_/  //'   | +---------+
   ___________________________/___  ',
  /  oooooooooooooooo  .o.  oooo /,   \,"-----------
 / ==ooooooooooooooo==.o.  ooo= //   ,'\--{)B     ,"
/_==__==========__==_ooo__ooo=_/'   /___________,"
'-----------------------------'

"@

# Variables de trabajo
$RND = Get-Random -Maximum 9
$CHIPSET = $env:PROCESSOR_IDENTIFIER[-12..-1] -join ''
$DRIVE = $PSScriptRoot.Substring(0,2)
$MOBO = wmic baseboard get manufacturer,product
$MOBO = $MOBO[2]

# Codigo principal
Write-Host '---------- Copiando fondo de pantalla ----------'
try {
    copy $DRIVE\FONDO_XT\BackgroundXtreme$RND.jpg $HOME\Pictures -ErrorAction Stop
    Write-Host 'Listo'
} catch {
    Write-Host 'ERROR: Verifique los archivos de la carpeta FONDO_XT' -BackgroundColor 'Red'
}
Write-Host ''

Write-Host '---------- Tarjeta madre ----------'
Write-Host $MOBO

if ($CHIPSET -eq 'GenuineIntel') {
# https://www.intel.com/content/www/us/en/download/19347/chipset-inf-utility.html?
    Write-Host 'Detectado Chipset Intel. Instalando controladores...'
    try {
        Start-Process -Wait $DRIVE\DRIVERS\Intel\Chipset\setup.exe -ArgumentList "-s -norestart" -ErrorAction Stop
        Write-Host 'Instalacion completada.'
    } catch {
        Write-Host 'ERROR: Verificar archivos de instalacion en la carpeta DRIVERS\Intel\Chipset\setup.exe' -BackgroundColor 'Red'
        Write-Host '¡Instalacion abortada!' -BackgroundColor 'Red'
    }
}
if ($CHIPSET -eq 'AuthenticAMD'){
# https://www.amd.com/es/support/kb/release-notes/rn-ryzen-chipset-3-10-08-506
    Write-Host 'Detectado Chipset AMD. Instalando controladores...'
    try {
        Start-Process -Wait $DRIVE\DRIVERS\AMD\Chipset\setup.exe -ArgumentList "-install" -ErrorAction Stop
        Write-Host 'Instalacion completada.'
    } catch {
        Write-Host 'ERROR: Verificar archivos de instalacion en la carpeta DRIVERS\AMD\Chipset\setup.exe' -BackgroundColor 'Red'
        Write-Host '¡Instalacion abortada!' -BackgroundColor 'Red'
    }
}
Write-Host ''

Write-Host '---------- Tarjeta de video ----------'
# Para Intel se usa el archivo "DRIVERS\Intel\Video_6+\Graphics_Gen9_Gen11\iigd_dch.inf" para cotejar con el hardware instalado y decidir el driver a instalar.
# https://www.intel.la/content/www/xl/es/download/19344/intel-graphics-windows-dch-drivers.html
$INF_Intel = Get-Content $DRIVE\DRIVERS\Intel\Video_6+\Graphics_Gen9_Gen11\iigd_dch.inf
$GPU_Intel = pnputil /enum-devices /class Display
$GPU_Intel = $GPU_Intel -like "*PCI\VEN_8086*"
try {
    $GPU_Intel = $GPU_Intel.Substring(37,17)
} catch {
    Write-Host 'No se encontraron graficos Intel en este equipo.'
}
for ($i=0; $i -le $GPU_Intel.Count-1; $i++) {
    if ($INF_Intel -match $GPU_Intel[$i]) {
        Write-Host "Intel Graphics encontrado. Instalando controlador..." $GPU_Intel
        Start-Process -Wait $DRIVE\DRIVERS\Intel\Video_6+\Installer.exe -ArgumentList "-s"
    }
}

# Para AMD se usa el archivo "DRIVERS\AMD\Radeon\Packages\Drivers\Display\WT6A_INF\U0384626.inf".
# https://www.amd.com/en/support/kb/release-notes/rn-rad-win-22-10-2
$INF_AMD = Get-Content $DRIVE\DRIVERS\AMD\Radeon\Packages\Drivers\Display\WT6A_INF\U0384626.inf
$GPU_AMD = pnputil /enum-devices /class Display
$GPU_AMD = $GPU_AMD -like "*PCI\VEN_1002*"
try {
    $GPU_AMD = $GPU_AMD.Substring(37,17)
} catch {
    Write-Host 'No se encontraron graficos AMD en este equipo.'
}
for ($i=0; $i -le $GPU_AMD.Count-1; $i++) {
    if ($INF_AMD -match $GPU_AMD[$i]) {
        Write-Host "AMD Radeon encontrado. Instalando controlador..." $GPU_AMD
        Start-Process -Wait $DRIVE\DRIVERS\AMD\Radeon\setup.exe -ArgumentList "-install"
        Start-Process -Wait $DRIVE\DRIVERS\AMD\Radeon-Legacy\setup.exe -ArgumentList "-install"
    }
}

# Para NVIDIA se usa el archivo "DRIVERS\NVIDIA\ListDevices.txt" generado con NVCleanstall y utilizando el driver version 522.25
$INF_NVIDIA = Get-Content $DRIVE\DRIVERS\NVIDIA\ListDevices.txt
$GPU_NVIDIA = pnputil /enum-devices /class Display
$GPU_NVIDIA = $GPU_NVIDIA -like "*PCI\VEN_10DE*"
try {
    $GPU_NVIDIA = $GPU_NVIDIA.Substring(37,17)
} catch {
    Write-Host 'No se encontraron graficos NVIDIA en este equipo.'
}
for ($i=0; $i -le $GPU_NVIDIA.Count-1; $i++) {
    if ($INF_NVIDIA -match $GPU_NVIDIA[$i]) {
        Write-Host "NVIDIA GeForce encontrado. Instalando controlador..." $GPU_NVIDIA
        Start-Process -Wait $DRIVE\DRIVERS\NVIDIA\setup.exe -ArgumentList "-s"
    }
}
Write-Host ''

Write-Host '---------- Instalando controladores de audio compatibles... ----------'
try {
    Start-Process -Wait $DRIVE\DRIVERS\Realtek\DM-034\Setup.exe -ArgumentList "/s" -ErrorAction Stop
    Write-Host 'Listo'
} catch {
    Write-Host 'ERROR: Verificar archivos de instalacion en la carpeta DRIVERS\Realtek\DM-034' -BackgroundColor 'Red'
}
Write-Host ''

Write-Host '---------- Instalando Office... ----------'
try {
    Start-Process -Wait $DRIVE\OFFICE_2013\setup.exe -ErrorAction Stop
    Write-Host 'Listo'
} catch {
    Write-Host 'ERROR: Verificar archivos de instalacion de Office en la carpeta OFFICE_2013' -BackgroundColor 'Red'
}
Write-Host ''

Write-Host '---------- Pre-activando Windows... ----------'
# Agradecimiento al paquete "MAS v1.6" del usuario "massgravel" de GitHub (https://github.com/massgravel/Microsoft-Activation-Scripts)
try {
    Start-Process -Wait $DRIVE\ACTIVADOR\Separate-Files-Version\HWID-KMS38_Activation\KMS38_Activation.cmd -ArgumentList "/a"
    Start-Process -Wait $DRIVE\ACTIVADOR\Separate-Files-Version\HWID-KMS38_Activation\HWID_Activation.cmd -ArgumentList "/a"
    Write-Host 'Listo'
} catch {
    Write-Host 'ERROR: Verificar archivos de instalacion de la carpeta ACTIVADOR' -BackgroundColor 'Red'
}
Write-Host ''

Write-Host '---------- Pre-activando Office... ----------'
# Agradecimiento al paquete "MAS v1.6" del usuario "massgravel" de GitHub (https://github.com/massgravel/Microsoft-Activation-Scripts)
try {
    Start-Process -Wait $DRIVE\ACTIVADOR\Separate-Files-Version\Online_KMS_Activation\Activate.cmd -ArgumentList "/wo"
    Start-Process -Wait $DRIVE\ACTIVADOR\Separate-Files-Version\Online_KMS_Activation\Activate.cmd -ArgumentList "/rat"
    Write-Host 'Listo'
} catch {
    Write-Host 'ERROR: Verificar archivos de instalacion de la carpeta ACTIVADOR' -BackgroundColor 'Red'
}
Write-Host ''

Write-Host '---------- Estableciendo fondo de pantalla... ----------'
Set-ItemProperty -path 'HKCU:\Control Panel\Desktop\' -name WallPaper -value $HOME\Pictures\BackgroundXtreme$RND.jpg
for ($i=0; $i -le 10; $i++) {
    rundll32.exe user32.dll,UpdatePerUserSystemParameters ,1 ,True
}
Write-Host 'Listo'
Write-Host ''

Write-Host '---------- Ejecutando CrystalDiskInfo... ----------'
try {
    Start-Process -Wait $DRIVE\HERRAMIENTAS\CrystalDiskInfo\DiskInfo64.exe -ArgumentList "/CopyExit"
    Move-Item $DRIVE\HERRAMIENTAS\CrystalDiskInfo\DiskInfo.txt $HOME\Desktop
    Write-Host 'Creado archivo de reporte en el escritorio.'
} catch {
    Write-Host 'ERROR: Verificar archivos de instalacion de CystalDiskInfo en la carpeta HERRAMIENTAS\CrystalDiskInfo' -BackgroundColor 'Red'
}

Write-Host '---------- Cambiando nombre de red... ----------'
$RND = Get-Random -Maximum 9999
Rename-Computer -NewName "User$RND-PC"
Write-Host 'Listo'
Write-Host ''

Stop-Transcript
Restart-Computer
