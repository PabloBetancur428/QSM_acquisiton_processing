#!/bin/bash
# This script compares two folders: one with processed patient directories
# and one with unprocessed patient directories. It prints the patient IDs that
# exist in the unprocessed folder but not in the processed folder.


# Define the directory containing processed patient folders.
processed_dir="/home/jbetancur/Desktop/Scripts_QSM/test/done_qsm"

# Define the directory containing unprocessed patient folders.
unprocessed_dir="/home/jbetancur/Desktop/Quspid_data/jpablo-20250305_164522"

# Loop over each patient folder in the unprocessed directory.
for patient in "$unprocessed_dir"/*/; do
    # Extract the patient ID from the folder name.
    patient_id=$(basename "$patient")
    
    # Check if this patient folder exists in the processed directory.
    if [ ! -d "$processed_dir/$patient_id" ]; then
        echo "Patient $patient_id has not been processed."
    fi
done