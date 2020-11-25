#!/usr/bin/env bash
## test_range_loop.sh
## Ensure couning over rows is correct.
## By: Ctrl-S
## Created: 2020-11-15
## Modified: 2020-11-15
echo "## Start of script."

## Use 'strict mode' for BASH to avoid bugs that can break something
set -euo pipefail ## WEB: https://devhints.io/bash
IFS=$'\n\t' ## WEB: http://redsymbol.net/articles/unofficial-bash-strict-mode/



## Options:
range_size="100"
min_imum="123"
max_imum="456"

	

echo -e "\n\n\n## == == == =="
echo "## range_size=${range_size}"
echo "## min_imum=${min_imum}"
echo "## max_imum=${max_imum}"
echo "AAAAAAA loop"
## Code:
let counter=$min_imum
while [[ $counter -le $max_imum ]]; do
	echo "## Cycle start. counter=${counter}"
	# Manage loop cycle (prefix)
	# Set high and low values for this cycle:
	let low_num=${counter}
	let high_num=${counter}+${range_size}
	# Prevent going past the maximum:
	if [[ $high_num -gt $max_imum ]]; then
		let high_num=$max_imum 
	fi
	## Display the low and high values for this cycle:
	echo "## low_num=${low_num}"
	echo "## high_num=${high_num}"
	# /Manage loop cycle (prefix)

	echo "Doing stuff"
	echo "$ mysqldump foo bar --where='SQL ${low_num} SQL SQL SQL ${high_num} SQL' baz"


	# Manage loop counter (postfix)
	let counter=${counter}+${range_size}
	echo -e "## loop end counter=${counter}\n"
	# /Manage loop cycle (postfix)
done



echo -e "\n\n\n## == == == =="
echo "## range_size=${range_size}"
echo "## min_imum=${min_imum}"
echo "## max_imum=${max_imum}"
echo "basic for loop"
for ((i = 0 ; i <= 10 ; i++)); do
	echo $i
done



echo -e "\n\n\n## == == == =="
echo "## range_size=${range_size}"
echo "## min_imum=${min_imum}"
echo "## max_imum=${max_imum}"
echo "1-value for loop"
for ((i = 0 ; i <= $max_imum ; i=${i}+${range_size} )); do
	echo "## cycle start i=${i}"
	echo "## i=${i}"
	echo "$ mysqldump foo bar --where='SQL ${i} SQL' baz" 
	
	echo -e "## cycle end i=${i}\n" 
done


echo -e "\n\n\n## == == == =="
echo "## range_size=${range_size}"
echo "## min_imum=${min_imum}"
echo "## max_imum=${max_imum}"
echo "2-value for loop"
## (2-value for loop)
## <Loop management>
for ((i = $min_imum ; i < $max_imum ; i=${i}+${range_size} )); do
	echo "## cycle start i=${i}" 
	let low_num=${i} 
	let high_num=${i}+${range_size}
	if [[ $high_num -gt $max_imum ]]; then
		let high_num=$max_imum # Prevent going past the maximum
	fi
	echo "## low_num=${low_num}"
	echo "## high_num=${high_num}"
	## </Loop management>

	echo "$ mysqldump foo bar --where='SQL ${low_num} SQL SQL SQL ${high_num} SQL' baz"

	echo -e "## cycle end i=${i}\n" 
done





echo "## End of script."
## == END OF SCRIPT ==
## NOTES / DOCUMENTATION
## LINK: https://ryanstutorials.net/bash-scripting-tutorial/bash-loops.php

