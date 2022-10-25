echo '============================================================'
echo '== Instalacion desatendida de drivers y programas de Windows.'
echo '== Script v0.6 basado en PowerShell, por Rob.'
echo '============================================================'
echo ''
echo ''
echo ''
echo ''

# Variables de trabajo
$RND = Get-Random -Maximum 9
$CHIPSET = $env:PROCESSOR_IDENTIFIER[-12..-1] -join ''
$DRIVE = $PSScriptRoot.Substring(0,2)
$MOBO = wmic baseboard get manufacturer,product
$MOBO = $MOBO[2]

# Codigo principal
echo '************************ Copiando fondo de pantalla.'
try {
    copy $DRIVE\FONDO_XT\BackgroundXtreme$RND.jpg $HOME\Pictures -ErrorAction Stop
    echo 'Copiado'
} catch {
    echo 'Archivo no encontrado. ¡Verifique los archivos de la carpeta FONDO_XT!'
}

echo '************************ Tarjeta madre:'
echo $MOBO
echo '************************'

if ($CHIPSET -eq 'GenuineIntel') {
# https://www.intel.com/content/www/us/en/download/19347/chipset-inf-utility.html?
    echo 'Detectado Chipset Intel. Instalando controladores...'
    try {
        Start-Process -Wait $DRIVE\DRIVERS\Intel\Chipset\setup.exe -ArgumentList "-s -norestart" -ErrorAction Stop
        echo 'Instalacion completada.'
    } catch {
        echo 'ERROR: Verificar archivos de instalacion en la carpeta DRIVERS\Intel\Chipset\setup.exe'
        echo '¡Instalacion abortada!'
    }
}
if ($CHIPSET -eq 'AuthenticAMD'){
# https://www.amd.com/es/support/kb/release-notes/rn-ryzen-chipset-3-10-08-506
    echo 'Detectado Chipset AMD. Instalando controladores...'
    try {
        Start-Process -Wait $DRIVE\DRIVERS\AMD\Chipset\setup.exe -ArgumentList "-install" -ErrorAction Stop
        echo 'Instalacion completada.'
    } catch {
        echo 'ERROR: Verificar archivos de instalacion en la carpeta DRIVERS\AMD\Chipset\setup.exe'
        echo '¡Instalacion abortada!'
    }
}

echo '************************* Tarjeta de video:'
# Para Intel se usa el archivo "DRIVERS\Intel\Video_6+\Graphics_Gen9_Gen11\iigd_dch.inf" para cotejar con el
# hardware instalado y decidir el driver a instalar.
# https://www.intel.la/content/www/xl/es/download/19344/intel-graphics-windows-dch-drivers.html
$GPU_Intel = pnputil /enum-devices /deviceid "PCI\VEN_8086"
$GPU_Intel = $GPU_Intel -like "*PCI\*"
try {
    $GPU_Intel = $GPU_Intel.Substring(37,17)
} catch {
    echo 'No se encontraron graficos Intel en este equipo.'
}

$INF_Intel = Get-Content $DRIVE\DRIVERS\Intel\Video_6+\Graphics_Gen9_Gen11\iigd_dch.inf

for ($i=0; $i -le $GPU_Intel.Count-1; $i++) {
    if ($INF_Intel -match $GPU_Intel[$i]) {
        echo "Tarjeta de video Intel Graphics encontrada. Instalando controlador..." $GPU_Intel[$i]
        Start-Process -Wait $DRIVE\DRIVERS\Intel\Video_6+\Installer.exe -ArgumentList "-p"
    }
}

# Para AMD se usa el archivo "DRIVERS\AMD\Radeon\Packages\Drivers\Display\WT6A_INF\U0380677.inf".
# https://www.amd.com/en/support/kb/release-notes/rn-rad-win-22-10-2
$GPU_AMD = pnputil /enum-devices /deviceid "PCI\VEN_1002"
$GPU_AMD = $GPU_AMD -like "*PCI\*"
try {
    $GPU_AMD = $GPU_AMD.Substring(37,17)
} catch {
    echo 'No se encontraron graficos AMD en este equipo.'
}

$INF_AMD = Get-Content $DRIVE\DRIVERS\AMD\Radeon\Packages\Drivers\Display\WT6A_INF\U0384626.inf

for ($i=0; $i -le $GPU_AMD.Count-1; $i++) {
    if ($INF_AMD -match $GPU_AMD[$i]) {
        echo "Tarjeta de video AMD Radeon encontrada. Instalando controlador..." $GPU_AMD[$i]
        Start-Process -Wait $DRIVE\DRIVERS\AMD\Radeon\setup.exe -ArgumentList "-install"
    }
}

# Para NVIDIA se usa el archivo "DRIVERS\NVIDIA\ListDevices.txt" generado con NVCleanstall.
$GPU_NVIDIA = pnputil /enum-devices /deviceid "PCI\VEN_10DE"
$GPU_NVIDIA = $GPU_NVIDIA -like "*PCI\*"
try {
    $GPU_NVIDIA = $GPU_NVIDIA.Substring(37,17)
} catch {
    echo 'No se encontraron graficos NVIDIA en este equipo.'
}

$INF_NVIDIA = Get-Content $DRIVE\DRIVERS\NVIDIA\ListDevices.txt

for ($i=0; $i -le $GPU_NVIDIA.Count-1; $i++) {
    if ($INF_NVIDIA -match $GPU_NVIDIA[$i]) {
        echo "Tarjeta de video NVIDIA GeForce encontrada. Instalando controlador..." $GPU_NVIDIA[$i]
        Start-Process -Wait $DRIVE\DRIVERS\NVIDIA\setup.exe -ArgumentList "-install"
    }
}

echo '********************************** Instalando Office...'
try {
    Start-Process -Wait $DRIVE\OFFICE_2013\setup.exe -ErrorAction Stop
    echo 'Instalacion completada.'
} catch {
    echo '¡Verificar archivos de instalacion de Office en la carpeta OFFICE_2013!'
    echo '¡Instalacion abortada!'
}


echo '********************************** Pre-activando Windows...'
# Agradecimiento al paquete de scripts del usuario "massgravel" de GitHub (https://github.com/massgravel/Microsoft-Activation-Scripts)
Start-Process -Wait $DRIVE\ACTIVADOR\Separate-Files-Version\HWID-KMS38_Activation\KMS38_Activation.cmd -ArgumentList "/a"
Start-Process -Wait $DRIVE\ACTIVADOR\Separate-Files-Version\HWID-KMS38_Activation\HWID_Activation.cmd -ArgumentList "/a"

echo '********************************** Pre-activando Office...'
# Agradecimiento al paquete MAS v1.6 del usuario "massgravel" de GitHub (https://github.com/massgravel/Microsoft-Activation-Scripts)
Start-Process -Wait $DRIVE\ACTIVADOR\Separate-Files-Version\Online_KMS_Activation\Activate.cmd -ArgumentList "/a"
Start-Process taskschd

echo '********************************** Estableciendo fondo de pantalla...'
Set-ItemProperty -path 'HKCU:\Control Panel\Desktop\' -name WallPaper -value $HOME\Pictures\BackgroundXtreme$RND.jpg
for ($i=0; $i -le 10; $i++) {
    rundll32.exe user32.dll,UpdatePerUserSystemParameters ,1 ,True
}
echo 'Hecho.'

Start-Process taskmgr
Start-Process devmgmt

#pause
