#!/bin/bash
#--------------------------------------------------------------
# This script should be used to run FX con jobs and then 
# calculate ACF parameters. It executes spm_job_residuals.sh
# for $SUB and matlab FX $SCRIPT
#	
# D.Cos 2018.11.06
#--------------------------------------------------------------

# Set the lab
LAB=sanlab

# Set your study
STUDY=PROP

# Set task name and session pattern
TASK=PROP
SES=ses-1

# Set subject list
SUBJLIST=`cat subject_list_test.txt`

# Which SID should be replaced?
REPLACESID=001

# SPM Path
SPM_PATH=/projects/sanlab/shared/spm12

# Set scripts directory path
SCRIPTS_DIR=/projects/sanlab/shared/${STUDY}/${STUDY}_scripts

# Set MATLAB script path
SCRIPT=${SCRIPTS_DIR}/fMRI/fx/models/fx_pmod.m

# Set shell script to execute
SHELL_SCRIPT=spm_job_residuals.sh

# RRV the results files
RESULTS_INFIX=fx_pmod

# Set output dir and make it if it doesn't exist
OUTPUTDIR=${SCRIPTS_DIR}/fMRI/fx/models/output

if [ ! -d ${OUTPUTDIR} ]; then
	mkdir -p ${OUTPUTDIR}
fi

# model output directory
MODEL_DIR=/projects/sanlab/shared/PROP/bids_data/derivatives/pmod/fx

# Make text file with residual files for each run
# echo $(printf "Res_%04d.nii\n" {1..245}) > residuals_run1.txt
# echo $(printf "Res_%04d.nii\n" {246..490}) > residuals_run2.txt

# Set job parameters
cpuspertask=1
mempercpu=8G

# Create and execute batch job
for SUB in $SUBJLIST; do

	RES_DIR=${MODEL_DIR}/sub-${SUB}

	sbatch --export ALL,REPLACESID=$REPLACESID,LAB=$LAB,STUDY=$STUDY,TASK=$TASK,SES=$SES,SCRIPT=$SCRIPT,SUB=$SUB,SPM_PATH=$SPM_PATH,RES_DIR=$RES_DIR  \
		--job-name=${RESULTS_INFIX} \
	 	-o ${OUTPUTDIR}/${SUB}_${RESULTS_INFIX}.log \
	 	--cpus-per-task=${cpuspertask} \
	 	--mem-per-cpu=${mempercpu} \
	 	--account=sanlab \
	 	${SHELL_SCRIPT}
		sleep .25
done
