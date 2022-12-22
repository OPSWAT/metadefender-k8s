#/bin/bash

function install-python () {
    mkdir -p $PWD/../scripts/miniconda
    wget https://repo.anaconda.com/miniconda/Miniconda3-py39_4.12.0-Linux-x86_64.sh -O $PWD/../scripts/miniconda/miniconda.sh
    bash $PWD/../scripts/miniconda/miniconda.sh -b -u -p $PWD/../scripts/miniconda/
    rm -f $PWD/../scripts/miniconda/miniconda.sh
}
function generate-packages () {
    echo "Generating .python_packages"
    ../scripts/miniconda/bin/python3.9 -m pip install -r ../src/requirements.txt -t ../src/.python_packages/lib/site-packages/ 
}

version=$(python -V 2>&1 | grep -Po '(?<=Python )(.+)')
if [ -z "$version" ]
then
    echo "Python not found!"
    version_temp=$(../scripts/miniconda/bin/python3.9 -V 2>&1 | grep -Po '(?<=Python )(.+)')
    if [ -z "$version_temp" ]
        then
            echo "Searching for temporary Python instalation"
            echo "Python not found! Downloading and installing Python 3.9 in a temporary folder." 
            install-python
            generate-packages
        else
            parsedVersion_temp=$(echo "${version//./}")
            if [ "$parsedVersion" -gt "3900" ]
                then 
                    echo "Valid version found. Temporary python version is $parsedversion"
                    generate-packages
                else
                    echo $parsedVersion_temp
                    echo "Invalid version. Downloading and installing Python 3.9 in a temporary folder. No changes will be made to your current python install." 
                    install-python
                    generate-packages
                fi
    fi
else
    parsedVersion=$(echo "${version//./}")
    if [ "$parsedVersion" -gt "3900" ]
    then 
        echo "Valid version found. Temporary python version is $parsedversion"
        python -m pip install -r ../src/requirements.txt -t ../src/.python_packages/lib/site-packages/

    else
        echo "Invalid version ($parserdVersion). Downloading and installing Python 3.9 in a temporary folder. No changes will be made to your current python install." 
        install-python
        generate-packages
        version_temp=$(../scripts/miniconda/bin/python3.9 -V 2>&1 | grep -Po '(?<=Python )(.+)')
        if [ -z "$version_temp" ]
            then
                echo "Searching for temp Python"
                echo "No Python! Downloading and installing Python 3.9 in a temporary folder." 
                install-python
                generate-packages
            else
            parsedVersion_temp=$(echo "${version_temp//./}")
            if [ "$parsedVersion_temp" -gt "3900" ]
                then 
                    echo "Temp Python version is $parsedVersion_temp"
                    echo "Valid version"
                    generate-packages
                else
                    echo $parsedVersion_temp
                    echo "Invalid version. Downloading and installing Python 3.9 in a temporary folder. No changes will be made to your current python installation." 
                    install-python
                    generate-packages
            fi
        fi
    fi
fi
