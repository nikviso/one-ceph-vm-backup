#!/bin/sh

#set -x
set -e

#DATE=$(date +"%F-%T");

#ZONE_SERVER_ID=0

usage() {
  echo "Usage: $0 -d bakup_path -p rbd_pool -z zone_server_id [-i vmid1[,vmid2,vmid3,...]] [-n vmname1[,vmname2,vmname3,...]] [-s runn[,stop,susp,...]] [-e exception_list_file] [-l log_file] [-v (verbose)]"
  exit 1
}

if [ $# -lt 1 ]; then
  usage
fi

while getopts d:e:i:l:n:p:s:vz: opt; do
  case "$opt" in
    d) BAKUP_PATH="$OPTARG"
    ;;
    e) EXCEPTION_LIST="$OPTARG"
    ;;
    i) VMID_IN="$OPTARG"
    ;;
    l) LOG_FILE_IN="$OPTARG"
    ;;
    n) VMNAME_IN="$OPTARG"
    ;;
    p) RBD_POOL="$OPTARG"
    ;;
    s) VM_STATUS=$(sed 's/,/\\|/g' <<< "$OPTARG")
    ;;
    v) VERBOSE=1
    ;;	
    z) ZONE_SERVER_ID="$OPTARG"
    ;;	
    \?)
    usage
    ;;
  esac
done

if [ $LOG_FILE_IN ]; then LOG_FILE=$(dirname $LOG_FILE_IN)/$(date +"%F")-$(basename $LOG_FILE_IN); fi


if [ ! "$RBD_POOL" -o ! "$BAKUP_PATH" -o ! "$ZONE_SERVER_ID" ]; then
 usage
fi

if [ $(onezone show 0 | grep leader | awk '{print $1}') -eq $ZONE_SERVER_ID ]; then 


if [[ $VMID_IN =~ ^[0-9,]+$ ]]; then
  VMID=$(sed 's/,/ /g' <<< "$VMID_IN");
  for VMID_ELEMENT in ${VMID[@]}; do
    VMNAME=$( onevm show $VMID_ELEMENT | sed 's/ //g' | grep "NAME:" | sed 's/NAME://;s/"//g;' )
    if [ $VMNAME ]; then 
	  VM_LIST+=($VMID_ELEMENT+$VMNAME); 
	else 
	  if [ $LOG_FILE_IN ]; then 
       echo "["$(date +"%F-%T")"] VM ID \"$VMID_ELEMENT\" not found!!!!!" >> $LOG_FILE;
	  else
	   if [ $VERBOSE ]; then echo "["$(date +"%F-%T")"] VM ID \"$VMID_ELEMENT\" not found!!!!!"; fi
	  fi
	fi
  done
elif [ $VMNAME_IN ]; then
  VMNAME=$(sed 's/,/ /g' <<< "$VMNAME_IN");
  for VMNAME_ELEMENT in ${VMNAME[@]}; do
    VMID=$( onevm show $VMNAME_ELEMENT | sed 's/ //g' |grep "VMID=" | sed 's/VMID=//;s/"//g;' )
	if [ $VMID ]; then
	 VM_LIST+=($VMID+$VMNAME_ELEMENT);
	else 
	 if [ $LOG_FILE_IN ]; then
	  echo "["$(date +"%F-%T")"] VM NAME \"$VMNAME_ELEMENT\" not found!!!!!" >> $LOG_FILE;
     else
      if [ $VERBOSE ]; then echo "["$(date +"%F-%T")"] VM NAME \"$VMNAME_ELEMENT\" not found!!!!!"; fi	 
	 fi 
	fi
  done
elif [ $VM_STATUS ]; then
  VM_LIST=( `onevm list | grep $VM_STATUS | awk '{print $1 "+" $4}'` ); 
  if [ $EXCEPTION_LIST ] && [ -f $EXCEPTION_LIST ]; then
   VM_EXCEPTION=( `cat $EXCEPTION_LIST | sed 's/[.,;:]/ /g'` );
   EXCEPTION_SET=1
  fi
else
  usage  
fi

for VM_ELEMENT in "${VM_LIST[@]}"; do

 while read VMID VMNAME; do 

  if [[ $EXCEPTION_SET = 1 ]]; then
   for EXCEPTION_ELEMENT in ${VM_EXCEPTION[@]}; do
    if [ $EXCEPTION_ELEMENT = $VMID ]; then EXCEPTION=1; fi
   done  
   if [[ $EXCEPTION = 1 ]]; then EXCEPTION=0; continue; fi
  fi
 
  NOW=$(date "+%Y%m%d%H%M%S")
  if ! [ -d $BAKUP_PATH/$VMNAME/$VMID ];
  then
   mkdir -p $BAKUP_PATH/$VMNAME/$VMID/$NOW;
  else
   mkdir $BAKUP_PATH/$VMNAME/$VMID/$NOW;
  fi

  if [ $LOG_FILE_IN ]; then
   echo "["$(date +"%F-%T")"] ========>"$VMID-$VMNAME >> $LOG_FILE;
  else
   if [ $VERBOSE ]; then echo "["$(date +"%F-%T")"] ========>"$VMID-$VMNAME; fi
  fi 

  onevm show $VMID --all -x > $BAKUP_PATH/$VMNAME/$VMID/$NOW/vm.xml;
  onevm show $VMID --all > $BAKUP_PATH/$VMNAME/$VMID/$NOW/vm.txt;

  while read IMAGE_ELEMENT;  do

    IMAGE_ELEMENT=$(sed 's/ //g' <<< "$IMAGE_ELEMENT")

    if [ $IMAGE_ELEMENT = "<DISK>" ]; then
     TRIGGER=1;
    fi   

    if [ $TRIGGER ]; then    
     if [[ $IMAGE_ELEMENT =~ .*"<IMAGE>".* ]]; then 
      IMAGE=$(echo $IMAGE_ELEMENT |  sed -e 's/<IMAGE><!\[CDATA\[//g; s/\]\]><\/IMAGE>//g';)
     fi
     if [[ $IMAGE_ELEMENT =~ .*"<IMAGE_ID>".* ]]; then 
      IMAGE_ID=$(echo $IMAGE_ELEMENT | sed -e 's/<IMAGE_ID><!\[CDATA\[//g; s/\]\]><\/IMAGE_ID>//g';)
     fi
     if [[ $IMAGE_ELEMENT =~ .*"<TYPE>".* ]]; then 
      TYPE=$(echo $IMAGE_ELEMENT | sed -e 's/<TYPE><!\[CDATA\[//g; s/\]\]><\/TYPE>//g';)
     fi
     if [[ $IMAGE_ELEMENT =~ .*"<SOURCE>".* ]]; then 
      SOURCE=$(echo $IMAGE_ELEMENT | sed -e 's/<SOURCE><!\[CDATA\[//g; s/\]\]><\/SOURCE>//g';)
     fi
    fi
   
    if [ $IMAGE_ELEMENT = "</DISK>" ]; then
      TRIGGER=0
      PERSISTENT=$(oneimage show $IMAGE_ID |  sed 's/ //g' | grep PERSISTENT | sed 's/PERSISTENT://'); 

      if [ $LOG_FILE_IN ]; then
        echo "["$(date +"%F-%T")"] ========>" >> $LOG_FILE;	  
        echo "["$(date +"%F-%T")"] IMAGE: "$IMAGE >> $LOG_FILE;   
        echo "["$(date +"%F-%T")"] IMAGE_ID: "$IMAGE_ID >> $LOG_FILE; 	 
        echo "["$(date +"%F-%T")"] TYPE: "$TYPE >> $LOG_FILE;	 
        echo "["$(date +"%F-%T")"] SOURCE: "$SOURCE >> $LOG_FILE;
        echo "["$(date +"%F-%T")"] PERSISTENT: "$PERSISTENT >> $LOG_FILE;
      else
	   if [ $VERBOSE ]; then 
             echo "["$(date +"%F-%T")"] ========>";	  
             echo "["$(date +"%F-%T")"] IMAGE: "$IMAGE;   
             echo "["$(date +"%F-%T")"] IMAGE_ID: "$IMAGE_ID; 	 
             echo "["$(date +"%F-%T")"] TYPE: "$TYPE;	 
             echo "["$(date +"%F-%T")"] SOURCE: "$SOURCE;
             echo "["$(date +"%F-%T")"] PERSISTENT: "$PERSISTENT;
	   fi	
      fi 

      if [[ $PERSISTENT = "No" ]]; then
        RBD_IMAGE=$(rbd -p $RBD_POOL ls | grep $IMAGE_ID-$VMID);
        if [ $LOG_FILE_IN ]; then
          echo "["$(date +"%F-%T")"] RBD_IMAGE: "$RBD_IMAGE >> $LOG_FILE;	  
        else
          if [ $VERBOSE ]; then echo "["$(date +"%F-%T")"] RBD_IMAGE: "$RBD_IMAGE; fi
        fi 
        DISK_LIST+=($RBD_POOL/$RBD_IMAGE@$RBD_IMAGE-$NOW+$BAKUP_PATH/$VMNAME/$VMID/$NOW/$RBD_IMAGE);
      elif [[ $PERSISTENT = "Yes" ]]; then
        RBD_IMAGE=$SOURCE;	
        if [ $LOG_FILE_IN ]; then
          echo "["$(date +"%F-%T")"] RBD_IMAGE: "$RBD_IMAGE >> $LOG_FILE;	  
        else
          if [ $VERBOSE ]; then echo "["$(date +"%F-%T")"] RBD_IMAGE: "$RBD_IMAGE; fi
        fi 
        DISK_LIST+=($RBD_IMAGE@$RBD_POOL-$IMAGE_ID-$NOW+$BAKUP_PATH/$VMNAME/$VMID/$NOW/$RBD_POOL-$IMAGE_ID);
	  else
        if [ $VERBOSE ]; then echo "["$(date +"%F-%T")"] $IMAGE_ID-$VMID not set as a persistent or non-persistent!!!"; fi
      fi
    fi

  done < $BAKUP_PATH/$VMNAME/$VMID/$NOW/vm.xml;
 
  LCM_STATE=$(onevm show $VMID | sed 's/ //g' | grep LCM_STATE: | sed 's/LCM_STATE://;s/"//g;')
  if [[ $LCM_STATE = "RUNNING" ]]; then
    onevm suspend $VMID;
    while true
    do
      VM_STATE=$(onevm show $VMID | sed 's/ //g' | grep STATE: | grep -v LCM_STATE: | sed 's/STATE://;s/"//g;')
      if [[ $VM_STATE = "SUSPENDED" ]]; then
       break
      else
       if [ $LOG_FILE_IN ]; then
         echo "["$(date +"%F-%T")"] Suspending VM ID" $VMID" ." >> $LOG_FILE;	  
       else
         if [ $VERBOSE ]; then echo "["$(date +"%F-%T")"] Suspending VM ID" $VMID"."; fi
       fi
       sleep 1
      fi
    done
  fi

  for DISK_ELEMENT in ${DISK_LIST[@]}; do
    while read SNAP; do 
     if [ $LOG_FILE_IN ]; then
       echo "["$(date +"%F-%T")"] Create snapshot "$SNAP"." >> $LOG_FILE;	  
     else
       if [ $VERBOSE ]; then echo "["$(date +"%F-%T")"] Create snapshot "$SNAP"."; fi
     fi 
     rbd snap create $SNAP;
    done <<< $(echo $DISK_ELEMENT | cut -f1 -d"+";)
  done

  if [[ $LCM_STATE = "RUNNING" ]]; then
    onevm resume $VMID;
    if [ $LOG_FILE_IN ]; then
      echo "["$(date +"%F-%T")"] Resume VM ID" $VMID" ." >> $LOG_FILE;	  
    else
      if [ $VERBOSE ]; then echo "["$(date +"%F-%T")"] Resume VM ID" $VMID"."; fi
    fi
  fi
  
  for DISK_ELEMENT in ${DISK_LIST[@]}; do
    while read SNAP BACKUP_SNAP; do 
     if [ $LOG_FILE_IN ]; then
       echo "["$(date +"%F-%T")"] Export snapshot" $SNAP "to" $BACKUP_SNAP"." >> $LOG_FILE;	  
     else
       if [ $VERBOSE ]; then echo "["$(date +"%F-%T")"] Export snapshot" $SNAP "to" $BACKUP_SNAP"."; fi
     fi
 	 if [ $VERBOSE ] && ! [ $LOG_FILE_IN ]; then 
      rbd export $SNAP $BACKUP_SNAP;
      rbd snap rm $SNAP; 	  
	 else
      rbd export $SNAP $BACKUP_SNAP > /dev/null 2>&1 &
      rbd snap rm $SNAP > /dev/null 2>&1 & 
	 fi
    done <<< $(echo $DISK_ELEMENT | sed 's/+/ /g';)
  done
 
  unset DISK_LIST;

 done <<< $(echo $VM_ELEMENT | sed 's/+/ /g';)

done

fi

#rm -r -f $BAKUP_PATH;
 
exit 0 
