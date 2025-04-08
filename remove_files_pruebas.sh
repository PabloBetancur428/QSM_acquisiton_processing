#!/bin/sh

set -x

# Define the base directory containing all patient folders.
base_dir="/home/jbetancur/Desktop/Scripts_QSM/test/prueba"

# Enable nullglob so that if a glob pattern matches no files, it expands to nothing.
shopt -s nullglob

# Iterate over each patient folder.
for patient in "$base_dir"/*/; do
  echo "Processing patient folder: $patient"
  
  # Iterate over each scan folder (year folder) starting with 2022, 2023, or 2024.
  for scan in "$patient"/{2022,2023,2024}*/; do
    echo "Processing scan folder: $scan"
    
    # For each of the "Magnitude" and "Phase" folders, delete files that do NOT match our pattern.
    for folder in "Magnitude" "Phase"; do
      target="$scan/$folder"
      if [ -d "$target" ]; then
        echo "Cleaning folder: $target"
        # Delete all files that do not have the substring "DICOM" and do not end with ".nii.gz".
        # The ! -name condition means "if the name does NOT match".
        find "$target" -type f ! -name "*DICOM*nii.gz" -delete
      fi
    done
    
    # Process the QSM folder: remove all files from QSM and its "romeo_unw" subfolder.
    target="$scan/QSM"
    if [ -d "$target" ]; then
      echo "Cleaning QSM folder: $target"
      find "$target" -maxdepth 1 -type f -delete
      if [ -d "$target/romeo_unw" ]; then
        find "$target/romeo_unw" -type f -delete
      fi
    fi
  done
done
