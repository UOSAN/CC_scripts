#!/bin/bash

# This script runs 3dClustSim for each model using acf parameters generated by calculate_group_average.R

module load afni

PARAMS=`cat ACFparameters_group_average.txt`

echo "running $MODEL"
3dClustSim -mask "${MODELDIR}"/"${MODEL}"/mask.nii -acf `echo "${PARAMS}"` > "${OUTPUTDIR}"/3dClustStim_"${MODEL}".txt