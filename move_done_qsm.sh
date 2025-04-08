#!/bin/bash
# This script moves patient folders that are finished with the QSM pipeline to a separate folder.

MAIN_DIR="/home/jbetancur/Desktop/Scripts_QSM/test/jpablo-20250305_164522"
DONE_DIR="/home/jbetancur/Desktop/Scripts_QSM/test/done_qsm"

#Insert the ID of the patients that are done with the QSM pipeline
done_patients=(19689534)


#Loop over finished patients
for pid in "${done_patients[@]}"; do

    patient_folder="$MAIN_DIR/$pid"

    #Check if patient folder exists

    if [ -d "$patient_folder" ]; then
        echo "Moving patient folder: $patient_folder to $DONE_DIR/"
        #Move entire folder to the destination dir
        mv "$patient_folder" "$DONE_DIR"/
    else
        echo "Patient folder $patient_folder not found."

    fi

done