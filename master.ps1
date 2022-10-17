echo '============================================================'
echo 'Instalación desatendida de drivers y programas de Windows.'
echo 'Script v0.6 basado en PowerShell, por Rob.'
echo '============================================================'

# Variables de trabajo
$RND = Get-Random -Maximum 9
$CHIPSET = $env:PROCESSOR_IDENTIFIER[-12..-1] -join ''
$DRIVE = $PSScriptRoot.Substring(0,2)
$MOBO = wmic baseboard get manufacturer,product
$MOBO = $MOBO[2]

# Código principal
echo '************************ Copiando fondo de pantalla.'
copy $DRIVE\FONDO_XT\BackgroundXtreme$RND.jpg $HOME\Pictures

echo '************************ Tarjeta madre:'
echo $MOBO

if ($CHIPSET -eq 'GenuineIntel') {
    echo 'Detectado Chipset Intel. Instalando controladores...'
    Start-Process -Wait $DRIVE\DRIVERS\Intel\Chipset\setup.exe -ArgumentList "-s -norestart"
    echo 'Instalación completada.'
}
if ($CHIPSET -eq 'AuthenticAMD'){
    echo 'Detectado Chipset AMD. Instalando controladores...'
    Start-Process -Wait $DRIVE\DRIVERS\AMD\Chipset\setup.exe -ArgumentList "-install"
    echo 'Instalación completada.'
}

echo '************************* Tarjeta de video:'
# Para Intel se usa el archivo "DRIVERS\Intel\Video_6+\Graphics_Gen9_Gen11\iigd_dch.inf" para cotejar con el
# hardware instalado y decidir el driver a instalar.
$GPU_Intel = pnputil /enum-devices /deviceid "PCI\VEN_8086"
$GPU_Intel = $GPU_Intel -like "*PCI\*"
$GPU_Intel = $GPU_Intel.Substring(37,17)

$INF_Intel = Get-Content $DRIVE\DRIVERS\Intel\Video_6+\Graphics_Gen9_Gen11\iigd_dch.inf

for ($i=0; $i -le $GPU_Intel.Count-1; $i++) {
    if ($INF_Intel -match $GPU_Intel[$i]) {
        echo "Tarjeta de video Intel Graphics encontrada. Instalando controlador..." $GPU_Intel[$i]
        Start-Process -Wait $DRIVE\DRIVERS\Intel\Video_6+\Installer.exe -ArgumentList "-p"
    }
}

# Para AMD se usa el archivo "DRIVERS\AMD\Radeon\Packages\Drivers\Display\WT6A_INF\U0380677.inf".
$GPU_AMD = pnputil /enum-devices /deviceid "PCI\VEN_1002"
$GPU_AMD = $GPU_AMD -like "*PCI\*"
$GPU_AMD = $GPU_AMD.Substring(37,17)

$INF_AMD = Get-Content $DRIVE\DRIVERS\AMD\Radeon\Packages\Drivers\Display\WT6A_INF\U0380677.inf

for ($i=0; $i -le $GPU_AMD.Count-1; $i++) {
    if ($INF_AMD -match $GPU_AMD[$i]) {
        echo "Tarjeta de video AMD Radeon encontrada. Instalando controlador..." $GPU_AMD[$i]
        Start-Process -Wait $DRIVE\DRIVERS\AMD\Radeon\setup.exe -ArgumentList "-install"
    }
}

# Para NVIDIA se usa el archivo "DRIVERS\NVIDIA\ListDevices.txt" generado con NVCleanstall.
$GPU_NVIDIA = pnputil /enum-devices /deviceid "PCI\VEN_10DE"
$GPU_NVIDIA = $GPU_NVIDIA -like "*PCI\*"
$GPU_NVIDIA = $GPU_NVIDIA.Substring(37,17)

$INF_NVIDIA = Get-Content $DRIVE\DRIVERS\NVIDIA\ListDevices.txt

for ($i=0; $i -le $GPU_NVIDIA.Count-1; $i++) {
    if ($INF_NVIDIA -match $GPU_NVIDIA[$i]) {
        echo "Tarjeta de video NVIDIA GeForce encontrada. Instalando controlador..." $GPU_NVIDIA[$i]
        Start-Process -Wait $DRIVE\DRIVERS\NVIDIA\setup.exe -ArgumentList "-install"
    }
}

echo '********************************** Instalando Office...'
Start-Process -Wait $DRIVE\OFFICE_2013\setup.exe
echo 'Instalación completada.'

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

echo '*********************************** Instalando controlador genérico de Audio que no depende de internet.'
# https://github.com/pal1000/Realtek-UAD-generic/releases/tag/6.0.9414.1
Start-Process -Wait $DRIVE\DRIVERS\Realtek\Unofficial-Realtek-UAD-generic-6.0.9414.1\Realtek-UAD-generic\setup.cmd
Start-Process -Wait $DRIVE\DRIVERS\Realtek\RealtekAudioControl_1.39.279-offline\RTKUWP\setup.cmd
echo 'Hecho.'

Start-Process taskmgr
Start-Process devmgmt

#pause
