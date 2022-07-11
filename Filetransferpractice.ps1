

#i need to check if a file exist then copy it to another location 

#check if the file exist  


$path1 = "C:\Program Files\Microsoft Office\root\Office 16\OUTLOOK.exe"
$path2 = "C:\Program Files\Microsoft Office\root\Office 16\WINWORD.exe"
$path3 = "C:\Program Files\Microsoft Office\root\Office 16\POWERPNT.exe"
$path4 = "C:\Program Files\Microsoft Office\root\Office 16\OneDrive.exe"
$path5 = "C:\Program Files\Microsoft Office\root\Office 16\EXCEL.exe"
$path6 = "C:\Users\AP\Downloads\Dream On.mp3"
$i = 6

$path = (Get-Variable ("path" + "$i")).Value
Write-Host $path
if (Test-Path -Path $path) {

    Write-Host "File Does Exist"
    Copy-Item $path -Destination C:\users\Public\Desktop

} else {

    Write-Host "CAP"
}
