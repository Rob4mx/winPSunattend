@ECHO OFF
SET ruta=%~dp0
SET rutaPowerShell=%ruta%master.ps1
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& '%rutaPowerShell%'";