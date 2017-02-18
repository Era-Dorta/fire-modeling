#!/bin/bash
function mailResult()
{
	if [ "$1" -eq 0 ]; then
		~/mailGaroe.sh "Test ${2} done"
	else
		~/mailGaroe.sh "Test ${2} failed"
	fi
}

# Tests to be run
TEST_NUM=76
START_FRAME=1
END_FRAME=11
DATA_FOLDER="~/maya/projects/fire/images/test112_like_111_volume0/hm_search_"

# First frame without extra argument
matlab -nodesktop -nosplash -r "args_test${TEST_NUM}($START_FRAME); exit();"
./runHeatMapReconstruction.sh "./test/data/args_test${TEST_NUM}.mat"
let START_FRAME=START_FRAME+1

# Other frames with previous frame folder
COUNTER=0
for i in `seq $START_FRAME $NUM_FRAMES`;
do
	# Create data file for current frame	
	matlab -nodesktop -nosplash -r "args_test${TEST_NUM}($i,'$DATA_FOLDER$COUNTER'); exit();"
	./runHeatMapReconstruction.sh "./test/data/args_test${TEST_NUM}.mat"
	let COUNTER=COUNTER+1
	mailResult $? $i
done
