#/bin/bash
ACTION=$1
PARAM1=$2
PARAM2=$3

if [[ $ACTION = "init" ]]
    then
    if [ -d ".bku" ] ; then echo "Error: Backup already initialized in this folder." ; exit 1
    else mkdir .bku ; touch .bku/track_files.txt ; touch .bku/history_log.log ; mkdir .bku/tracked_files
		 echo "Backup initialized."
         echo "$(date '+%H:%M-%d/%m/%Y'): BKU Init." >> .bku/history_log.log
    fi
elif [[ $ACTION != "stop" && ! -d ".bku" ]] ; then echo "Must be a BKU root folder." ; exit 1
elif [[ $ACTION = "add" ]] ; then
    if [[ $PARAM1 = "" ]]
        then find * -type f | while read line 
             do if [[ $(grep -Fx $line .bku/track_files.txt) = "" ]] ; then echo "Added $line to backup tracking."
                     cp --parent $line .bku/tracked_files ; touch .bku/tracked_files/$line.patch ; echo $line >> .bku/track_files.txt
                fi
             done
    else
        if [[ ! -f $PARAM1 ]] ; then echo "Error: ${PARAM1#./} does not exist." ; exit 1 ; fi
        CURR_FILE=${PARAM1#./}
        if [[ $(grep -Fx $CURR_FILE .bku/track_files.txt) = "" ]] ; then echo "Added $CURR_FILE to backup tracking."
             cp --parent $CURR_FILE .bku/tracked_files ; touch .bku/tracked_files/$CURR_FILE.patch ; echo $CURR_FILE >> .bku/track_files.txt
        else echo "Error: $CURR_FILE is already tracked." ; exit 1 ; fi
    fi
elif [[ $ACTION = "status" ]] ; then
    if [[ $(cat .bku/track_files.txt) = "" ]] ; then echo "Error: Nothing has been tracked." ; exit 1
    elif [[ $PARAM1 = "" ]] ; then cat .bku/track_files.txt | while read line
        do patch -f -s .bku/tracked_files/$line < .bku/tracked_files/$line.patch
        diff_output="$(diff -U 3 .bku/tracked_files/$line $line)"
        if [[ $diff_output = "" ]] ; then echo "$line: No changes"
        else echo "$line:" ; echo "$diff_output" | tail -n +3 ; fi
        patch -f -R -s .bku/tracked_files/$line < .bku/tracked_files/$line.patch ; done
    else CURR_FILE=${PARAM1#[./]} ; CURR_FILE=${CURR_FILE#/}
        if [[ $(grep $CURR_FILE .bku/track_files.txt) = "" ]]
        then echo "Error: $CURR_FILE is not tracked." ; exit 1
        else patch -f -s .bku/tracked_files/$CURR_FILE < .bku/tracked_files/$CURR_FILE.patch
             diff_output="$(diff -U 3 .bku/tracked_files/$CURR_FILE $CURR_FILE)"
             if [[ $diff_output = "" ]] ; then echo "$CURR_FILE: No changes"
             else echo "$CURR_FILE:" ; echo "$diff_output" | tail -n +3 ; fi
             patch -f -R -s .bku/tracked_files/$CURR_FILE < .bku/tracked_files/$CURR_FILE.patch
        fi
    fi
elif [[ $ACTION = "commit" ]] ; then
    if [[ $PARAM1 = "" ]] ; then echo "Error: Commit message is required."
    elif [[ $PARAM2 = "" ]] ; then modified_files="" ; curr_date=$(date '+%H:%M-%d/%m/%Y')
        while read line
            do patch -f -s .bku/tracked_files/$line < .bku/tracked_files/$line.patch
            if [[ $(diff -U 3 .bku/tracked_files/$line $line) = "" ]]
                then patch -f -R -s .bku/tracked_files/$line < .bku/tracked_files/$line.patch
            else diff -U 3 .bku/tracked_files/$line $line > .bku/tracked_files/$line.patch
                 echo "Committed $line with ID $curr_date."
                 modified_files+=",$line" ; fi
        done < .bku/track_files.txt
        if [[ $modified_files = "" ]] ; then echo "Error: No change to commit." ; exit 1
        else echo "$curr_date: $PARAM1 (${modified_files/,/})." >> .bku/history_log.log ; fi
    else CURR_FILE=${PARAM2#[./]} ; CURR_FILE=${CURR_FILE#/}
        if [[ $(grep -w $CURR_FILE .bku/track_files.txt) = "" ]]
            then echo "Error: No change to commit." ; exit 1
        else patch -f -s .bku/tracked_files/$CURR_FILE < .bku/tracked_files/$CURR_FILE.patch
             modified_file="" ; curr_date=$(date '+%H:%M-%d/%m/%Y')
             if [[ $(diff -U 3 .bku/tracked_files/$CURR_FILE $CURR_FILE) = "" ]]
                then patch -f -R -s .bku/tracked_files/$CURR_FILE < .bku/tracked_files/$CURR_FILE.patch
             else diff -U 3 .bku/tracked_files/$CURR_FILE $CURR_FILE > .bku/tracked_files/$CURR_FILE.patch
                  echo "Committed $CURR_FILE with ID $curr_date."
                  modified_file="$CURR_FILE" ; fi
             if [[ $modified_file = "" ]] ; then echo "Error: No change to commit." ; exit 1
             else echo "$curr_date: $PARAM1 ($modified_file)." >> .bku/history_log.log ; fi
        fi
    fi
elif [[ $ACTION = "history" ]]
    then tail -n +2 .bku/history_log.log ; head -1 .bku/history_log.log
elif [[ $ACTION = "restore" ]]
    then
    if [[ $(cat .bku/track_files.txt) = "" ]] ; then echo "Error: No file to be restored." ; exit 1
    elif [[ $PARAM1 = "" ]] ; then changed="FALSE" ; while read line
        do patch -f -s .bku/tracked_files/$line < .bku/tracked_files/$line.patch
           if [[ $(diff -U 3 .bku/tracked_files/$line $line) != "" ]]
           then patch -f -R -s .bku/tracked_files/$line < .bku/tracked_files/$line.patch
           elif [[ $(cat .bku/tracked_files/$line.patch) != "" ]]
           then patch -f -R -s .bku/tracked_files/$line < .bku/tracked_files/$line.patch
                patch -f -R -s $line < .bku/tracked_files/$line.patch
                echo "Restored $line to its previous version."
                grep $line .bku/history_log.log | tail -1 | grep -v -Fx -f - .bku/history_log.log > .bku/history_log.temp
                mv .bku/history_log.temp .bku/history_log.log
                changed="TRUE"
           fi
        done < .bku/track_files.txt
        if [[ $changed = "FALSE" ]] ; then echo "Error: No file to be restored." ; exit 1 ; fi
    else CURR_FILE=${PARAM1#[./]} ; CURR_FILE=${CURR_FILE#/}
         if [[ $(grep -w $CURR_FILE .bku/track_files.txt) = "" ]]
         then echo "Error: No file to be restored." ; exit 1
         else patch -f -s .bku/tracked_files/$CURR_FILE < .bku/tracked_files/$CURR_FILE.patch
              if [[ $(diff -U 3 .bku/tracked_files/$CURR_FILE $CURR_FILE) != "" ]]
              then patch -f -R -s .bku/tracked_files/$CURR_FILE < .bku/tracked_files/$CURR_FILE.patch
                   echo "Error: No previous version available for $CURR_FILE." ; exit 1
              elif [[ $(cat .bku/tracked_files/$CURR_FILE.patch) != "" ]]
              then patch -f -R -s .bku/tracked_files/$CURR_FILE < .bku/tracked_files/$CURR_FILE.patch
                   patch -f -R -s $CURR_FILE < .bku/tracked_files/$CURR_FILE.patch
                   echo "Restored $CURR_FILE to its previous version."
                   grep $CURR_FILE .bku/history_log.log | tail -1 | grep -v -Fx -f - .bku/history_log.log > .bku/history_log.temp
                   mv .bku/history_log.temp .bku/history_log.log
              else echo "Error: No file to be restored." ; exit 1 ; fi
         fi
    fi
elif [[ $ACTION = "schedule" ]]
    then
    crontab -u $(whoami) -l &> /dev/null || echo -n | crontab -
    if [[ $PARAM1 = "--daily" ]]
    then crontab -u $(whoami) -l | grep -v "bash $(realpath $0) commit ${PWD##*/}" | crontab -u $(whoami) -
         (crontab -u $(whoami) -l ; echo "@daily cd $PWD && bash $(realpath $0) commit Scheduled backup" ) | crontab -u $(whoami) -
         echo "Scheduled daily backups at daily."
    elif [[ $PARAM1 = "--hourly" ]]
    then crontab -u $(whoami) -l | grep -v "bash $(realpath $0) commit ${PWD##*/}" | crontab -u $(whoami) -
         (crontab -u $(whoami) -l ; echo "@hourly cd $PWD && bash $(realpath $0) commit ${PWD##*/}" ) | crontab -u $(whoami) -
         echo "Scheduled daily backups at hourly."
    elif [[ $PARAM1 = "--weekly" ]]
    then crontab -u $(whoami) -l | grep -v "bash $(realpath $0) commit ${PWD##*/}" | crontab -u $(whoami) -
         (crontab -u $(whoami) -l ; echo "@weekly cd $PWD && bash $(realpath $0) commit ${PWD##*/}" ) | crontab -u $(whoami) -
         echo "Scheduled weekly backups at weekly."
    elif [[ $PARAM1 = "--minutely" ]]
    then crontab -u $(whoami) -l | grep -v "bash $(realpath $0) commit ${PWD##*/}" | crontab -u $(whoami) -
         (crontab -u $(whoami) -l ; echo "* * * * * cd $PWD && bash $(realpath $0) commit ${PWD##*/}" ) | crontab -u $(whoami) -
         echo "Scheduled minutely backups at minutely."
    elif [[ $PARAM1 = "--off" ]]
    then
         crontab -u $(whoami) -l | grep -v "bash $(realpath $0) commit ${PWD##*/}" | crontab -u $(whoami) -
         echo "Backup scheduling disabled."
    fi
elif [[ $ACTION = "stop" ]]
    then if [[ ! -d ".bku" ]] ; then echo "Error: No backup system to be removed." ; exit 1
         else rm -rf .bku ; echo "Backup system removed."
              crontab -u $(whoami) -l | grep -v "bash $(realpath $0) commit Scheduled backup" | crontab -u $(whoami) -
         fi
fi
