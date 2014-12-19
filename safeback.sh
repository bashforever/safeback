#!/bin/bash
#: Name: safeback
#: Version: 0.0
#: Datum: 15.12.2014
#: Purpose: safeback does a backup from SOURCE to TARGET using ignore-existing. This means files already existing in TARGET are ignored. But safeback also cleans up: 
#: after Backup it reverses operation and scans TARGET for files not existing in SOURCE. These are moved to subfolder (created if not existing) ./Safe
#: so after execution of safeback you can inspect ./Safe and - if you feel save with a sync - you can delete content or entire directory ./Safe.
#
# 

# Global Params

LOGFILE=/etc/iwops/safeback.log

# ===================== function LOGTEXT ======================================
# Parameter: Text der ins Logfile geschrieben werden soll
# function for writing text to logfile
logtext () {
   echo "`date`: " $1 2>&1 | tee -a $LOGFILE
}   

# ===================== function BACKUP ======================================
# Parameter: source directory, target directory
# Does: Phase 1 Backup is done recursively, Phase 2: moving source-free files not!!

backup () {
	local SOURCE=$1
	local TARGET=$2
	# ===== Phase 1: recursive backup from source to target =====
	# source (example): /mnt/AMS150/Videos/Panasonic
	# target (example): /media/Share/Medien/Videos/Panasonic
	
	logtext "=== backup from $SOURCE to $TARGET ===="
	rsync --recursive --verbose --ignore-existing "$SOURCE/" "$TARGET" 2>&1 | tee -a $LOGFILE
	logtext "=== backup finished ==="
	
	return 0
	
	}

# ===================== function SAFEBACK ======================================
# Parameter: source directory, target directory
# Caution: Phase 1 Backup is done recursively, Phase 2: moving source-free files not!!

safeback () {
	local SOURCE=$1
	local TARGET=$2
	local SAVE="Save"
	
	# ===== Phase 2: check target for files not being in source and move them to ./Save ====
	cd "$TARGET"
	# check existence of directory "Save"
	if [ -e $SAVE ]; then
	#	check Save for being a directory
		if [ -d $SAVE ]; then 
	# Save exists and is directory --> everything OK
			logtext "=== directory save exists ==="
		else
			logtext "ERROR: save is no directory"
			exit 1
		fi

	else
	# Save does not exist --> create	
		logtext "creating Save"
		mkdir $SAVE
		if [  $? -eq 0  ] ; then
			logtext "==== save successful created ====="
		else
	# creation failed
			logtext "ERROR: creation of save in $TARGET failed"
			exit 1
		fi
	fi
		
	# directory Save has been successful created - make it available
	chmod 777 $SAVE

	# now loop over all files in TARGET and if exists also in source - move to ./Save
	cd "$TARGET"
	for d in *; do
	# HERE we could enter recursion! (ie checking for $d being a directory and then cd-ing to it and starting safeback again recursively)
		cd "$SOURCE"
	# now check in SOURCE for current object being a directory: if so, dir to it and start safeback recursively
		if [ -d "$d"  ] && [  "$d" != "$SAVE" ]; then
	# object is directory (and not SAVE)
			logtext "==== jumping to subdir $d ===="
	# recursively call safeback!
			safeback "$SOURCE/$d" "$TARGET/$d"
		else
	# object is no directory: process as file
			if [  -e "$d" ]; then
	# file exists in SOURCE: do nothing
				logtext "===== $d exists in SOURCE ====="
			else
	# file does not exist in SOURCE: move to Save (exclude Save!)
				if [ "$d" != "$SAVE" ]; then
					mv "$TARGET/$d" "$TARGET/$SAVE"
					logtext "===== moved $d to SAVE"
				fi
			fi
		fi
	done

	return 0	
}
# END of Safeback



# ============================ MAIN ===================================

logtext "******************* Starting safeback ******************************"

# nun wird der AMS150 gemountet - Abbruch wenn's nicht funktioniert
mountpoint /mnt/AMS150
if [ $? -eq 0 ] ; then
 	logtext "/mnt/AMS150 is already mounted" 
else
# mounten durchführen
 	logtext "/mnt/AMS150 nicht mounted - versuche zu mounten" 
 	mount /mnt/AMS150 2>&1 | tee -a $LOGFILE
fi

# nochmal testen: falls Fehler: Abbruch
mountpoint /mnt/AMS150
if [ $? -eq 0 ] ; then
 	logtext "/mnt/AMS150 ist nun gemountet" 
else
# abbruch
 	logtext "/mnt/AMS150 mount fehlgeschlagen! ABBRUCH " 
 	exit 1
fi

# mount of AMS150 done. Start backup in pairs of source and target
# ================================================================
# CAUTION: this section only contains several sample paths - real OPERATIONS requires more paths!
# ================================================================
SOURCE1="/media/Recs/Aufnahmen/Lieblingsfilme"
TARGET1="/mnt/AMS150/Videos/Lieblingsfilme"
backup $SOURCE1 $TARGET1
safeback $SOURCE1 $TARGET1

SOURCE1="/media/Recs/Aufnahmen/Sophia"
TARGET1="/mnt/AMS150/Videos/Sophia"
backup $SOURCE1 $TARGET1
safeback $SOURCE1 $TARGET1

SOURCE1="/media/Recs/Aufnahmen/DVDs"
TARGET1="/mnt/AMS150/Videos/DVDs"
backup $SOURCE1 $TARGET1
safeback $SOURCE1 $TARGET1


exit 0

# End of Main


# EOF
