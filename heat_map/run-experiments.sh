#!/bin/bash
function mailResult()
{
	if [ "$1" -eq 0 ]; then
		~/mailGaroe.sh "Test ${2} done"
	else
		~/mailGaroe.sh "Test ${2} failed"
	fi
}

# Regenerate the test data using the matlab functions
matlab -nodesktop -nosplash -r "generate_all_test_data(); exit();"

# Number of the tests to be ran
TEST_NUMS=(75)
for i in ${TEST_NUMS[@]}; do
	./runHeatMapReconstruction.sh "./test/data/args_test${i}.mat"
	mailResult $? $i
done
