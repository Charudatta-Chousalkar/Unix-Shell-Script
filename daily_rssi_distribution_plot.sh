#!/bin/bash
#
#  $Id: daily_rssi_distribution_plot.sh 139875 2020-09-20 15:44:38Z cchousal $
#
#  Author: Charudatta
#

usage() {
    cat >&2 <<EOF
usage: $0 <options>
    -a              - act_rssi
    -b              - bact_rssi
    -o              - outfile
EOF
exit -1
}


while getopts "a:b:o:" OPT; do
    case $OPT in
        a)
            act_rssi=$OPTARG
            ;;
        b)
            bact_rssi=$OPTARG
            ;;
        o)
            outfile=$OPTARG
            ;;
        ?)
            usage
            ;;
    esac
done

if [[ (! -e $act_rssi || $act_rssi == "") && (! -e $bact_rssi || $bact_rssi == "") ]]; then

 usage

fi


R --no-save --no-restore-data --no-restore-history --slave --quiet << EOF
library(ggplot2)
#library('dplyr')
options(scipen = 999)
theme_set(theme_bw() + theme(text = element_text(size = 20, family = "Times")))

if(file.access("$act_rssi") == -1) {
  act_rssi <- data.frame(matrix(0, nrow=1, ncol=4))
  colnames(act_rssi) = c('id','val','type','color')
} else {
  act_rssi <- read.csv("$act_rssi",header=F, sep='')
  act_rssi <- act_rssi[,c('V1','V8')]
  colnames(act_rssi) = c('id','val')
  act_rssi <- cbind(act_rssi,type="Electric",color="Blue")
}

if(file.access("$bact_rssi") == -1) {
  bact_rssi <- data.frame(matrix(0, nrow=1, ncol=4))
  colnames(bact_rssi) = c('id','val','type','color')
} else {
  bact_rssi <- read.csv("$bact_rssi",header=F, sep='')
  bact_rssi <- bact_rssi[,c('V1','V8')] 
  colnames(bact_rssi) = c('id','val')
  bact_rssi <- cbind(bact_rssi,type="Gas / Water",color="Purple")
}
rssi <- rbind(act_rssi,bact_rssi)
rssi <- subset(rssi,val<0)
png("$outfile", width = 1200, height = 800)
ggplot(rssi, aes(x=val)) +
  geom_histogram(bins = 1000, binwidth = 1) +
  facet_wrap( ~ type, scales = "free_y", ncol = 1) +
  labs(x= 'Mesh RSSI' , y= 'Meter Counts', title = 'Distribution Of RSSI')

q()
EOF
