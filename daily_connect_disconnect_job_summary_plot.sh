#!/bin/bash
#
#  $Id: daily_connect_disconnect_job_summary_plot.sh 139921 2020-09-29 04:14:29Z cchousal $
#
#  Author: Charudatta
#

usage() {
    cat >&2 <<EOF
usage: $0 <options>
    -a              - conn_disconn_details.txt file
    -o              - outfile
EOF
exit -1
}

#defaults

while getopts "a:o:" OPT; do
    case $OPT in
        a)
            connect=$OPTARG
            ;;
        o)
            outfile=$OPTARG
            ;;
        ?)
            usage
            ;;
    esac
done

if [[ (! -e $connect || $connect == "") ]]; then

 usage

fi


R --no-save --no-restore-data --no-restore-history --slave --quiet << EOF
library(ggplot2)
library(stringr)
options(scipen = 999)
theme_set(theme_bw() + theme(text = element_text(size = 20, family = "Times")))

connect <- read.csv("$connect",header=F, sep='')
colnames(connect) <- c('JobKey','ESN','Type','ResultCode','SubmittedTime','StartTime','CompletedTime')
connect\$SubmittedTime <- as.Date(str_replace(connect\$SubmittedTime, '_',' '))
connect\$StartTime <- as.POSIXlt(str_replace(connect\$StartTime, '_',' '))
connect\$CompletedTime <- as.POSIXlt(str_replace(connect\$CompletedTime, '_',' '))
connect\$JobTime <- difftime(connect\$CompletedTime,connect\$StartTime,units='mins')

connect\$Result[connect\$ResultCode==17019] <- 'Success'
connect\$Result[connect\$ResultCode==17019 & connect\$JobTime>30] <- 'Success but JobTime > 30mins'
connect\$Result[connect\$ResultCode==17003] <- 'No Response'
connect\$Result[connect\$ResultCode==17006] <- 'Command Rejected'
connect\$Result[connect\$ResultCode!=17003 & connect\$ResultCode!=17006 & connect\$ResultCode!=17019] <- connect\$ResultCode
#table(connect\$ResultCode)
#table(connect\$Result)
#str(connect)

png("$outfile", width = 1200, height = 800)
ggplot(connect,aes(x=Result,fill = Result,decreasing=FALSE)) + 
  geom_bar(position = "dodge") +
  facet_wrap( ~ Type, scales = "free_y", ncol = 1) +
  labs(x= 'Job Results' , y= 'Endpoint Count', title = 'Connect Disconnect Job Summary') +
  scale_fill_manual("legend", values = c("Success" = "DarkGreen", "No Response" = "orange", "Command Rejected" = "Red")) +
#  geom_text(stat="count",aes(label=..count.., vjust=-1)) +  
  theme_bw()
  
q()
EOF

