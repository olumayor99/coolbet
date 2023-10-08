awk -F: '{if($3 > 100){print $0}}' /etc/passwd | sort -t ':' -k 3 -n > /tmp/passwd.txt

export status_1=$?

awk -F: '{if($3 >= 0 && $3 <= 100){print $0}}' /etc/passwd | sort -t ':' -k 3 -r -n >>/tmp/passwd.txt

export status_2=$?

echo "--Sorting ids >100 completed with status $status_1, while sorting ids <=100 also completed with status $status_2--"