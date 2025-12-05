#!/bin/bash/


#loading the log file 
 

#LOG_FILE="server_monitor.log"

#LOG_FILE="/home/reddy/server_monitor/server_monitor.log"

LOG_FILE="/home/reddy/server_monitor/logs/monitor.log"

log() {
    echo "$(date) | $1" >> "$LOG_FILE"
}
#Monitoring process



	#get CPU process
	
	#CPU=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')

	CPU=$(mpstat 1 1 | awk '/Average/ {printf "%.2f", 100 - $12}')

	#CPU=$(mpstat 1 1 | awk '/all/ {printf "%.2f", 100 - $NF}')

	#CPU=$(top -bn1 | awk '/Cpu/ {print $2}' | sed 's/%//')
	#get memory process
	MEMORY=$(free | grep Mem | awk '{print $3/$2 * 100.0}')

	#read DISK 
	
	DISK=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')

	#read ping
	
	#PING=$(ping -c 1 google.com | grep 'time=' | awk -F'time=' '{print $2}' | cut -d '' -f1)
	
	#PING=$(ping -c 1 google.com | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print $1}')

 	PING=$(ping -c 1 google.com 2>/dev/null | awk -F'time=' '/time=/ {print $2}' | sed 's/ ms//')	


	if [ -z "$PING" ]
	then
		PING="Fail"
	fi
	#Retreiving data into log file  
	#echo "$(date) | CPU : $CPU% | MEM : $MEMORY% | DISK : $DISK% | LATENCY : ${PING}ms" >> $LOG_FILE
	
	echo "$(date) | CPU:$CPU% | MEM:${MEMORY}% | DISK:${DISK}% | LATENCY:${PING}ms" >> $LOG_FILE

	#print data
	
	echo "$(date) | cpu:$CPU | MEM : $MEMORY | DISK: $DISK | NET : $PING"

	flag=0

	if (( $(echo " $CPU > 90 " | bc -l) ))
	#if awk "BEGIN {exit !($CPU > 50)}"
	then
		echo "$(date)  Alert : High CPU usage detected " | tee -a $LOG_FILE
		
		#find the cpu pids
		high_cpu_pid=$(ps -eo pid,ppid,cmd,%cpu --sort=-%cpu | grep -v '\[.*\]' |grep -v systemd |awk 'NR==2 {print $1}')
		
		#kill high process cpus
		#kill -9 $high_cpu_pid
		echo "High CPU on server at $(date): $CPU%" | mail -s "Server CPU Alert" 22951a6614@iare.ac.in
		echo "$(date) |  high cpu process killed PID=$high_cpu_pid" | tee -a $LOG_FILE
		echo "$(date) | high CPU process detected PID=$high_cpu_pid" 
	fi

	if (( $(echo " $MEMORY > 85" | bc -l) ))
	then
		echo "$(date) |Alert : High Ram Detected! ($MEMORY%)" | tee -a $LOG_FILE

		#find the old temp files
		
		files=$(du -ah . | sort -rh)

		log "ALERT: High Memory Usage ($MEMORY%)"

		echo "ram usage is high ! ($MEMORY%) delete some heavy files ($files)"


	fi

	if [ "$DISK" -ge 80 ]
	then
		echo "$(date) High DIsk Usage clear some temporary files " | tee -a $LOG_FILE
		
		log "ALERT: Disk Usage Above 90% ($DISK%)"
		echo "Temp files to dlt are : ($DISK)"
	fi

	if [ "$PING" == "Fail" ]
	then
		echo "$(date) Network Down Alert " | tee -a $LOG_FILE	
		
		systemctl restart NetworkManager 2>/dev/null

		echo "$(date) | Network issue Fixed"
	fi

	sleep 5s

















