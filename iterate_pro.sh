#!/bin/bash
# This script organizes QSM files for each patient into group directories.
# Each patient folder will have subdirectories named by the year extracted from the QSM filename.
# Files with sequential trailing numbers are grouped together.
# If a gap is found (i.e. the current trailing number is not previous+1),
# a new group is created and its folder is named with a suffix (e.g., 2024_2).
# Within each group folder, three directories are created at the same level: QSM, Phase, and Magnitude.
# Files whose names contain "ph" (case-insensitive) are moved to the Phase directory;
# otherwise, they are moved to the Magnitude directory.
# Note: This script assumes that the QSM filenames follow the pattern:
# "DICOM_t1_fl3d_sag_qsm_<date>_<trailing>[optional _ph].nii.gz"
# where <date> is a string (e.g., "20240317083836") and the first 4 digits represent the year.
# It also assumes that each patient folder may have multiple acquisitions (different date parts)
# and, for a given date, sequential QSM files are expected to have trailing numbers that differ by exactly 1.
# If not, a new group folder (e.g., "2024_2") is created.

# Set the main path where patient folders are located.
main_path="/home/jbetancur/Desktop/Quspid_data/jpablo-20250305_164522"  # <-- CHANGE THIS to your actual main directory path

# Iterate over each patient folder inside the main path.
for patient in "$main_path"/*/; do
    echo "Processing patient folder: $patient"
    
    # Find all QSM files in the patient folder (recursively).
    # We assume QSM files end with .nii.gz and match the pattern.
    qsm_files=$(find "$patient" -type f -iname "DICOM_t1_fl3d_sag_qsm_*.nii.gz" | sort)
    
    # Initialize variables to track grouping per date.
    prev_date=""    # To store the date part of the previous file
    prev_trail=0    # To store the trailing number of the previous file
    group_index=0   # To track which group we are in for a given date
    
    # Process each found QSM file.
    for qsm in $qsm_files; do
        # Extract the base filename.
        filename=$(basename "$qsm")
        
        # Remove the known prefix to get the remaining part.
        # Example: from "DICOM_t1_fl3d_sag_qsm_20240317083836_51.nii.gz"
        # we get "20240317083836_51.nii.gz"
        temp=${filename#DICOM_t1_fl3d_sag_qsm_}
        
        # Extract the date part: everything up to the first underscore.
        date_part=${temp%%_*}   # e.g., "20240317083836"
        
        # Extract the trailing part (after the first underscore).
        trailing_full=${temp#*_}  # e.g., "51.nii.gz" or "52_ph.nii.gz"
        
        # Extract the numeric part at the beginning (the trailing number).
        trailing_number=$(echo "$trailing_full" | grep -o '^[0-9]\+')
        
        # For a new date (i.e. a different acquisition) reset the grouping.
        if [ "$date_part" != "$prev_date" ]; then
            prev_date="$date_part"
            prev_trail="$trailing_number"
            group_index=1
        else
            # If same date, check if the current trailing number is exactly previous+1.
            if [ $((prev_trail + 1)) -eq "$trailing_number" ]; then
                # Sequential file: same group.
                prev_trail="$trailing_number"
            else
                # Non-sequential: increment group counter.
                group_index=$((group_index + 1))
                prev_trail="$trailing_number"
            fi
        fi
        
        # Extract the year from the date part (first 4 characters).
        year=${date_part:0:4}
        
        # Decide the target group folder name.
        # If group_index is 1, the folder is named just by the year (e.g., "2024").
        # Otherwise, it is named "year_groupIndex" (e.g., "2024_2").
        if [ "$group_index" -eq 1 ]; then
            target_dir="$patient/$year"
        else
            target_dir="$patient/${year}_$group_index"
        fi
        
        # Create the folder structure if it doesn't exist.
        # We create three directories: QSM, Phase, and Magnitude at the same level.
        if [ ! -d "$target_dir" ]; then
            echo "Creating folder structure for $target_dir"
            mkdir -p "$target_dir/QSM" "$target_dir/Phase" "$target_dir/Magnitude"
        fi
        
        # Determine the destination based on whether the filename contains "ph" (case-insensitive).
        if echo "$filename" | grep -qi "ph"; then
            dest="$target_dir/Phase"
            echo "File $filename classified as Phase."
        else
            dest="$target_dir/Magnitude"
            echo "File $filename classified as Magnitude."
        fi
        
        # Optionally, if you want to also store the original file in the QSM folder,
        # you could copy or move it there as well. For now, we only move it to Phase/Magnitude.
        echo "Moving file $qsm to $dest/"
        mv "$qsm" "$dest/"
    done
done
