#!/bin/bash
#--------------------------------------------------------------
# This script:
#	* Creates a batch job for $SUB
#	* Batch jobs are saved to the path defined in MATLAB script
#	* Executes batch job
#	* Merges residuals for each run separately
#	* Calculates ACF parameters for each run separately
#	* Averages ACF parameters and saves in ACRRVarameters_average.1D
#
# D.Cos 2018.11.06
#--------------------------------------------------------------

# set options and load matlab
SINGLECOREMATLAB=true
ADDITIONALOPTIONS=""

if "$SINGLECOREMATLAB"; then
	ADDITIONALOPTIONS="-singleCompThread"
fi

# create and execute job
echo -------------------------------------------------------------------------------
echo "${SUB}"
echo "Running ${SCRIPT}"
echo -------------------------------------------------------------------------------

module load matlab
matlab -nosplash -nodisplay -nodesktop ${ADDITIONALOPTIONS} -r "clear; addpath('$SPM_PATH'); spm_jobman('initcfg'); sub='$SUB'; script_file='$SCRIPT'; replacesid='$REPLACESID'; run('make_sid_matlabbatch.m'); spm_jobman('run',matlabbatch); exit"

# specify residuals
echo -------------------------------------------------------------------------------
echo "Specifying residuals"
echo -------------------------------------------------------------------------------
module load afni
sub_bids_dir=/projects/${LAB}/shared/${STUDY}/bids_data/sub-${SUB}/${SES}/func
RUNS=$(ls *${TASK}*.nii.gz | wc -l)
start=1
stop=0

for i in $(seq 1 $RUNS); do 
	file=${sub_bids_dir}/sub-${SUB}_${SES}_task-${TASK}${i}_bold.nii.gz
	nvols=`3dinfo -nv ${file}`
	stop=$(($stop + $nvols))
	for j in $(seq $start $stop); do 
		printf "Res_%04d.nii\n" $j >> ${RES_DIR}/residuals_run${i}.txt 
	done
	start=$(($start + $nvols))
done

# merge residual files
echo -------------------------------------------------------------------------------
echo "Merging residuals"
echo -------------------------------------------------------------------------------

module load fsl
cd ${RES_DIR}

for i in $(seq 1 $RUNS)
	do echo "merging residuals for run${i}"
	residual_files=`cat ${RES_DIR}/residuals_run${i}.txt`
	fslmerge -t residuals_run${i} ${residual_files}
	rm ${residual_files}
done

# run 3dFWHMx
echo -------------------------------------------------------------------------------
echo "Calculating ACF parameters"
echo -------------------------------------------------------------------------------

module load afni
for i in $(seq 1 $RUNS)
	do echo "calculating ACF parameters for run${i}"
	3dFWHMx -acf -mask mask.nii residuals_run${i}.nii.gz >> ACFparameters.1D
done

# average ACF parameters
echo -------------------------------------------------------------------------------
echo "Averaging ACF parameters"
echo -------------------------------------------------------------------------------
3dTstat -mean -prefix - ACFparameters.1D'{1..$(2)}'\' >> ACFparameters_average.1D
