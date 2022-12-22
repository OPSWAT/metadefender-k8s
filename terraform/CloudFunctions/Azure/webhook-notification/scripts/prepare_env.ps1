# redirect stderr into stdout
$version = &{python -V} 2>&1
$version_temp =  &{..\scripts\Python\python -V} 2>&1
function install-python {
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12; `
    Invoke-WebRequest -UseBasicParsing -Uri "https://www.python.org/ftp/python/3.9.13/python-3.9.13-embed-amd64.zip" -Out '../scripts/Python.zip'; `
    Expand-Archive -Path "../scripts/Python.zip" -DestinationPath "../scripts/Python/" -Force; `
    Write-Host "Installing PIP"
    Invoke-WebRequest -UseBasicParsing -Uri "https://bootstrap.pypa.io/get-pip.py" -OutFile '../scripts/Python/get-pip.py'
    .\..\scripts\Python\python.exe ..\scripts\Python\get-pip.py --disable-pip-version-check --no-cache-dir --no-warn-script-location
    Write-Host "Generating .python_packages"
    .\..\scripts\Python\Scripts\pip install -r ..\src\requirements.txt -t ..\src\.python_packages\lib\site-packages\
    Remove-Item -Force ..\scripts\python.zip
    remove-item -force ..\scripts\Python\python39._pth_
    }

# check if an ErrorRecord was returned
if($version -is [System.Management.Automation.ErrorRecord])
{
Write-Host "Python not found! Checking for temporary python."
  if($version_temp -is [System.Management.Automation.ErrorRecord]){
    write-host "Python not found! Downloading and installing Python 3.9 in a temporary folder"
    install-python
    } 
    else {
      $parsedVersion_temp = $version_temp.Replace("Python ","").Replace(".","")
        if ([int]$parsedVersion_temp -gt 3900) {
            Write-Host "Valid version found. Temporary python version is $parsedversion_temp" 
            .\..\scripts\Python\python.exe -m pip install -r ..\src\requirements.txt -t ..\src\.python_packages\lib\site-packages\ 
        }
        else { 
            Write-Host "Invalid version ($parsedversion_temp). Downloading and installing Python 3.9 in a temporary folder. No changes will be made to your current python install."
            install-python
        }
    }
}
else 
{
    $parsedVersion = $version.Replace("Python ","").Replace(".","")
    if ([int]$parsedVersion -gt 3900) {
        Write-Host "Valid version found. Local Python version is $parsedversion"
        python -m pip install -r ..\src\requirements.txt -t ..\src\.python_packages\lib\site-packages\
    }
    else{
        Write-Host "Invalid version found ($parsedversion)! Checking for temporary python."
           if ([int]$parsedVersion_temp -gt 3900) {
            Write-Host "Valid version found. Temporary python version is $parsedversion_temp" 
            .\..\scripts\Python\python.exe -m pip install -r ..\src\requirements.txt -t ..\src\.python_packages\lib\site-packages\ 
           }
            else { 
                Write-Host "Invalid version ($parsedversion_temp). Downloading and installing Python 3.9 in a temporary folder. No changes will be made to your current python install."
                install-python
        }
    }
}