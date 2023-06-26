Add-Type -AssemblyName System.Windows.Forms
$FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -ErrorAction Stop -Property @{
    InitialDirectory = [Environment]::GetFolderPath('MyComputer')
    Filter = 'Archivos INF (*.inf)|*.inf'
    }

try {
    Write-Host 'Especifique la ruta donde se encuentra el archivo INF del paquete de controladores AMD.'
    $null = $FileBrowser.ShowDialog()
    # Las arquitecturas mostradas abajo no son de escritorio.

    $file = $FileBrowser | Select -ExpandProperty FileName
    $temp = Get-Content $file

    $temp = $temp | Where-Object {$_ -notmatch 'PicassoAM4'}
    $temp = $temp | Where-Object {$_ -notmatch 'Picasso2'}
    $temp = $temp | Where-Object {$_ -notmatch 'Renoir2'}
    $temp = $temp | Where-Object {$_ -notmatch 'RenoirAM4'}
    $temp = $temp | Where-Object {$_ -notmatch 'RavenAM4'}
    # Laptop uarch
    $temp = $temp | Where-Object {$_ -notmatch 'Mendocino'}
    $temp = $temp | Where-Object {$_ -notmatch 'Barcelo'}
    $temp = $temp | Where-Object {$_ -notmatch 'DragonRange'}
    $temp = $temp | Where-Object {$_ -notmatch 'Rembrandt'}
    # Unknown uarch
    $temp = $temp | Where-Object {$_ -notmatch 'R7500'}
    # Legacy
    $temp = $temp | Where-Object {$_ -notmatch 'Legacy'}

    $trim_start = $temp | Select-String -Pattern 'Driver information' | Select -ExpandProperty LineNumber
    $trim_end = $temp | Select-String -Pattern 'General installation section' | Select -ExpandProperty LineNumber
    $temp = $temp[($trim_start+2)..($trim_end-4)]
    Set-Content -Path .\Hardware_Radeon.txt -Value $temp
    Write-Host 'Archivo creado en la misma carpeta que este script.'
    Start-Sleep -Seconds 5
} catch { }
