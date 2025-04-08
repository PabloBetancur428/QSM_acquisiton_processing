#!/bin/sh
# @ORIGINAL_AUTHOR_QSM_EXTRACTION: Emma Biondetti, PhD
# @ADAPTATION_FOR_CEMCAT_DATABASE: Juan Pablo Betancur, MsC
# @DATE: 23/01/2025
# @DESCRIPTION: Adapted QSM pipeline script. Modified for reproducibility on our dataset and enhanced for integration with the CEMCAT database.
#
# Script that runs the QSM pipeline.
#
set -x
pp=/home/jbetancur/Desktop/Scripts_QSM/test/jpablo-20250305_164522
SCRIPT_DIR=$pp

qsm_pip=/home/jbetancur/Desktop/Scripts_QSM/test/codes_bash
qsm_pip_dir=$qsm_pip

# Enable nullglob so that if a glob pattern matches no files, it expands to nothing.
shopt -s nullglob

# Iterate over each patient folder inside the main path.
for patient in "$pp"/*/; do
  echo "Processing patient folder: $patient"
  
  # Iterate over each scan folder within the patient folder that starts with "2022", "2023", or "2024"
  for scan_dir in "$patient"/{2022,2023,2024}*/; do
    # If no directory matches, the loop won't iterate.
    echo "Processing scan folder: $scan_dir"
    WRK_DIR="$scan_dir"

    # CReate the "romeo_unw" folder inside QSM
    mkdir -p "$WRK_DIR/QSM/romeo_unw"
    
    # --- Begin QSM pipeline (unchanged) ---
    
    # 1. Rescaling the phase image to the [-pi,pi) range
    GRE_PH=$(find $WRK_DIR/Phase/*nii.gz)
    
    in_min_max=`fslstats $GRE_PH -R`
    in_min=`echo "$in_min_max" | cut -d ' ' -f 1`
    in_max=`echo "$in_min_max" | cut -d ' ' -f 2`
    in_range=`echo "$in_max - $in_min" | bc -l`
    fslmaths $GRE_PH -sub $in_min -div $in_range -mul 6.28318 -sub 3.14159 $WRK_DIR/Phase/phase_rad.nii.gz
    
    # 2. Running ROMEO for phase unwrapping  and B0 map calculation
    GRE_MAG=$(find $WRK_DIR/Magnitude/*nii.gz)
    cp $GRE_MAG $WRK_DIR/Magnitude/mag.nii.gz
    gunzip $WRK_DIR/Magnitude/mag.nii.gz
    gunzip $WRK_DIR/Phase/phase_rad.nii.gz
    
  
    /home/jbetancur/mritools_ubuntu-22.04_4.5.3/bin/romeo -p $WRK_DIR/Phase/phase_rad.nii -m $WRK_DIR/Magnitude/mag.nii -t "[2.4,4.55,6.67,8.85,11,13.15,15.3]" -o $WRK_DIR/QSM/romeo_unw -B --phase-offset-correction bipolar -v
    gzip $WRK_DIR/QSM/romeo_unw/*nii
    
    # 3. Removing temporary files
    gzip $WRK_DIR/Magnitude/mag.nii
    gzip $WRK_DIR/Phase/phase_rad.nii
    
    # 4. Calculating brain mask (using FSL BET and FLIRT)
    # Robustfov is used to adjust the field of view before brain extraction
    # After brain extraction, the mask is registered back to the original field of view
    cd $WRK_DIR/Magnitude
    fslsplit $WRK_DIR/Magnitude/mag.nii.gz mag -t
    robustfov -i $WRK_DIR/Magnitude/mag0006 -r $WRK_DIR/Magnitude/mag0006_robustfov
    bet $WRK_DIR/Magnitude/mag0006_robustfov $WRK_DIR/Magnitude/mag0006_robustfov_brain -f 0.5 -g 0 -m
    flirt -in $WRK_DIR/Magnitude/mag0006_robustfov.nii.gz -ref $WRK_DIR/Magnitude/mag0006.nii.gz -out $WRK_DIR/Magnitude/mag0006_robustfov_backwardReg.nii.gz -omat $WRK_DIR/Magnitude/mag0006_robustfov_backwardReg.mat -bins 256 -cost corratio -searchrx 0 0 -searchry 0 0 -searchrz 0 0 -dof 12 -interp trilinear
    flirt -in $WRK_DIR/Magnitude/mag0006_robustfov_brain_mask.nii.gz -applyxfm -init $WRK_DIR/Magnitude/mag0006_robustfov_backwardReg.mat -out $WRK_DIR/Magnitude/mag0006_robustfov_brain_mask_backwardReg.nii.gz -paddingsize 0.0 -interp nearestneighbour -ref $WRK_DIR/Magnitude/mag0006.nii.gz
    
    # 5. Running the rest of the QSM pipeline in Matlab
    matlab -nodesktop -r "cd('$qsm_pip_dir'); QSM_proc('$WRK_DIR'); exit" 
    set +x

    printf "QSM processing is done \n"
    
  done
  patient_id=$(basename "$patient")
  if ! grep -qx "$patient_id" /home/jbetancur/Desktop/Scripts_QSM/test/processed_patients.txt; then
    echo "$patient_id" >> /home/jbetancur/Desktop/Scripts_QSM/test/processed_patients.txt
  fi
done