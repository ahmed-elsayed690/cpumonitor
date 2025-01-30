#!/bin/bash

# Default threshold and log file
THRESHOLD=80
LOGFILE="system_monitor.log"

# Function to display colored text
color() {
    # $1 is the text and $2 is the color code (e.g., 31 for red)
    echo -e "\033[${2}m${1}\033[0m"
}

# Parse optional arguments
while getopts "t:f:" opt; do
    case ${opt} in
        t) # Threshold for disk usage
            THRESHOLD=$OPTARG
            ;;
        f) # Output log file
            LOGFILE=$OPTARG
            ;;
        *)
            echo "Usage: $0 [-t threshold] [-f logfile]"
            exit 1
            ;;
    esac
done

# Create/clear log file
echo "System Monitoring Report - $(date)" > $LOGFILE
echo "---------------------------------" >> $LOGFILE

# 1. Check Disk Usage
echo -e "Disk Usage:" >> $LOGFILE
df -h | awk 'NR>1 {print $1, $5}' | while read line; do
    partition=$(echo $line | cut -d' ' -f1)
    usage=$(echo $line | cut -d' ' -f2 | sed 's/%//')
    
    # Report disk usage and issue warning if it exceeds threshold
    if [ $usage -gt $THRESHOLD ]; then
        color "Warning: Disk usage on $partition is at $usage%" 31
        echo "Warning: Disk usage on $partition is at $usage%" >> $LOGFILE
    else
        echo "$partition - $usage%" >> $LOGFILE
    fi
done

# 2. Check CPU Usage
cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
echo -e "\nCPU Usage: $cpu_usage%" >> $LOGFILE

# 3. Check Memory Usage
memory=$(free -h | awk 'NR==2{print "Total: " $2 ", Used: " $3 ", Free: " $4}')
echo -e "\nMemory Usage: $memory" >> $LOGFILE

# 4. Check Top 5 Memory Consuming Processes
echo -e "\nTop 5 Memory Consuming Processes:" >> $LOGFILE
ps aux --sort=-%mem | head -n 6 | tail -n 5 | awk '{print $1, $3, $11}' >> $LOGFILE

# 5. Report Generation
echo -e "\nReport saved to $LOGFILE."

# Send an email if threshold exceeded (optional, requires mailutils or similar)
# Uncomment below to send an email when a threshold is breached

# if [ -f "$LOGFILE" ]; then
#     mail -s "System Monitor Report" user@example.com < $LOGFILE
# fi

# Display final message with color
color "System Monitoring Complete. Report saved in $LOGFILE." 32
