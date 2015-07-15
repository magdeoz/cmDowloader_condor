#!/bin/bash


ADB=$(adb shell grep -o ${cm-12.1}'-........-NIGHTLY-'${condor} /system/build.prop | head -n1) #Reads the currently installed CM-version from your device's /system/build.prop. 

CURL=$(curl -s 'https://download.cyanogenmod.org/?device='${condor} | grep -o ${cm-12.1}'-........-NIGHTLY-'${condor} | head -n1 | grep ${cm-12.1}'-........-NIGHTLY-'${condor} ) #Searches the CyanogenMod-website of your device for the latest update.

MD5=$(curl -s 'https://download.cyanogenmod.org/?device='${condor} | grep -o 'md5sum: ................................' | cut -c 8-40 | head -n1) #Gets the md5-hash for the latest update

WGETURL=$(curl -s 'https://download.cyanogenmod.org/?device='${condor} | grep -v 'jen' | grep -o -m1 'http://get.cm/get/...' | head -n1) #Selects the most recent direct-link to the CyanogenMod-zip



versionVerifier(){
	if [[ -n ${ADB} ]]; then
		echo 'Your current CyanogenMod-version is' ${ADB} 
		updateChecker
	else
		echo
		echo 'error: Your specified CyanogenMod-version and the device-version differ, or your device is not connected properly. Exiting'
		exit
	fi
}


updateChecker(){
	if [[ ${ADB} < ${CURL} ]]; then
		read -p "An updated version is available (cm-${CURL}). Do you want to download it? (y/n/a)" -n 1 -r
		echo 
			if [[ $REPLY =~ ^[Yy]$ ]]; then
    				updateDownloader
			fi
			if [[ $REPLY =~ ^[Nn]$ ]]; then
    				read -p "Do you want to reboot your device into recovery and create a backup (requires TWRP)? (y/n/a)" -n 1 -r
					if [[ $REPLY =~ ^[Yy]$ ]]; then
						backupCreator
					else
						echo
						echo "Exiting. Have a nice day!"
					fi
			fi
			if [[ $REPLY =~ ^[Aa]$ ]]; then
				echo
				echo 'Exiting...'
				exit
			fi
	else	
		read -p "No update is available. Do you want to reboot your device into recovery and create a backup (requires TWRP)? (y/n/a)" -n 1 -r
			if [[ $REPLY =~ ^[Yy]$ ]]; then
				backupCreator
			else
				echo
				echo "Exiting. Have a nice day!"
				exit
			fi
	fi
}

updateDownloader(){
	if [ -f "${./}'cm-${CURL}.zip'" ]; then
		read -p "Update found at ${/} (cm-${CURL}.zip). Do you want to overwrite?" -n 1 -r
		echo 
		if [[ $REPLY =~ ^[Yy]$ ]]; then
			updateDownloader2
		else
			echo
			echo 'Exiting...'
			exit
		fi
	else
		mkdir -p ${/}
		updateDownloader2
	fi
}

updateDownloader2(){
wget ${WGETURL} -O "${/}'cm-'${CURL}.zip"
echo ${MD5} > ${/}'cm-'${CURL}'.zip.md5'
read -p "Update and MD5 downloaded. Do you want to reboot your device into recovery and create a backup of your device? (y/n/a)" -n 1 -r
echo 
	if [[ $REPLY =~ ^[Yy]$ ]]; then
    		backupCreator
	else
		echo
		echo 'Exiting. Your update is located at' ${/}
		exit
	fi
}

backupCreator(){
adb reboot recovery
echo
echo 'Waiting for device...'
sleep 30
adb shell twrp backup SDB
twrpBackupremover
}

twrpBackupremover(){
	if [ -d ${/}'/backup' ]; then
		read -p "Updates finished. Old backups found on your PC. Do you want to remove them? (y/n/a)" -n 1 -r
		echo 
		if [[ $REPLY =~ ^[Yy]$ ]]; then
    			rm -r ${/}'backup/'
			echo 'Removed old backups.'
			twrpBackup
		fi
		if [[ $REPLY =~ ^[Nn]$ ]]; then
			twrpBackup
		fi
		if [[ $REPLY =~ ^[Aa]$ ]]; then
			echo
			echo 'Exiting...'
			exit
		fi
	else
		twrpBackup
	fi
}

twrpBackup(){
read -p "Backup finished. Do you want to copy it to your PC and remove it from the device? (y/n/a)" -n 1 -r
echo 
	if [[ $REPLY =~ ^[Yy]$ ]]; then
    		adb pull /sdcard/TWRP/BACKUPS/ ${/}'backup/'
		adb shell rm -r /sdcard/TWRP/BACKUPS/
		echo
		echo 'Moved backups to the PC and removed them from the device.'
		rebooter
	else
		rebooter
		
	fi
}

rebooter(){
echo
read -p "Do you want to reboot your device? (y/n/a)" -n 1 -r
			if [[ $REPLY =~ ^[Yy]$ ]]; then
				adb reboot
				echo
			else
				echo
				echo 'Exiting. Have a nice day!'
			fi
}


versionVerifier
