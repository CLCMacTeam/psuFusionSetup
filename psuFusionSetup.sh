#!/bin/bash

# Written by Rusty Myers
# 2013-04-08

# Script to create fusion drives
# Use the following command to delete the Fusion Drive Setup:
# diskutil cs delete $CoreStorageUUID

# ToDo:
# Add test for machine types - we only want to create fusion drives on MacPros
# Add test for existing fusion drives

#--------------------------------------------------------------------------------------------------
#-- Log - Echo messages with date and timestamp
#--------------------------------------------------------------------------------------------------
Log ()
{
	logText=$1
	# indent lines except for program entry and exit
	if [[ "${logText}" == "-->"* ]];then
		logText="${logText}`basename $0`: launched..."
	else
		if [[ "${logText}" == "<--"* ]];then
			logText="${logText}`basename $0`: ...terminated" 
		else
		logText="   ${logText}"
		fi
	fi
	date=$(/bin/date)
	echo "${date/E[DS]T /} ${logText}"
}

Log "-->"

# Checking for existing CS UUIDs
CoreStorageUUID=`diskutil cs list | awk '/Logical Volume Group/ {print $5}'`
if [[ -z $CoreStorageUUID ]]; then
	echo "No Core Storage"
else
	echo "Found CS LLVG: $CoreStorageUUID"
	diskutil cs delete $CoreStorageUUID
	if [[ $? == 0 ]]; then
		Log "Success, Fusion Deleted!"
	else
		Log "Failed to remove Fusion Drive! Trying to erase each Disk!"
		diskutil eraseDisk HFS+ D0 disk0
		diskutil eraseDisk HFS+ D1 disk1
	fi
fi


# Reset Variables
SSD=""
HDD=""
UUID=""
DiskListArrayNumber=0

# Set new name of Fusion Drive volume
VOLUMENAME="Macintosh HD"
GROUPNAME="CLCFusion"

# Build array of internal disks in Mac (disk0, disk1, disk2, etc...)
DiskList=`diskutil list | grep "/dev/"`

for i in $DiskList; do
	# Run through each disk connected
	
	# Yes if internal
	if [[ `diskutil info $i |awk '/^   Internal:/ {print $2}'` = "Yes" ]]; then
		Log "Disk $i is Internal"
		# echo "Disk array number: $DiskListArrayNumber"
		# Set array with internal disk
		DiskListArray[$DiskListArrayNumber]="$i"
		# Increment array
        DiskListArrayNumber=$(expr $DiskListArrayNumber + 1)
	# Disabling else statement because we don't need to see how many drives are not internal
	# else
		# Not internal, ignore
		# echo "Disk $i is NOT Internal"
	fi

done

Log "There are ${#DiskListArray[@]} internal disks in the DiskListArray"

if [[ "${#DiskListArray[@]}" < 2 ]];then
	Log "Not enough disks to make fusion drive!"
	exit 0
fi

# Get disk IDs for ssd and platter, set into variables for SSD and HDD
for i in "${DiskListArray[@]}"; do
	Log "Checking $i for disk type (SSD/HDD)"
	if [[ `diskutil info $i |awk '/^   Solid State:/ {print $3}'` = "Yes" ]]; then
		SSD="$i"
	else
		HDD="$i"
	fi
done

Log "Internal Drives are:"
Log "	SSD: $SSD"
Log "	HDD: $HDD"

# Create core storage group
diskutil cs create $GROUPNAME $SSD $HDD

# Set UUID from new CoreStorage Group
CoreStorageUUID=`diskutil cs list | awk '/Logical Volume Group/ {print $5}'`
Log "New CoreStorage Group UUID: $CoreStorageUUID"

# Sleep so core storage drives can settle for a second
sleep 5

# Create new volume from CS group UUID
Log "Running: diskutil cs createVolume $CoreStorageUUID jhfs+ \"$VOLUMENAME\" 100%"
diskutil cs createVolume $CoreStorageUUID jhfs+ "$VOLUMENAME" 100%

Log "Fusion Drive: `diskutil cs list | grep -A10 "        +-> Logical Volume "| awk '/Volume Name:/ {print $3}'`"
Log "New Fusion Drive setup complete."


Log "<--"
