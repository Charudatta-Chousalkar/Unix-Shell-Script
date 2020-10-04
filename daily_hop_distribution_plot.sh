#!/bin/bash
#
#  $Id: daily_hop_distribution_plot.sh 139870 2020-09-18 15:57:39Z cchousal $
#
#  Author: Charudatta
#

usage() {
    cat >&2 <<EOF
usage: $0 <options>
    -a              - act_hop
    -b              - bact_hop
    -o              - outfile
EOF
exit -1
}

#defaults

while getopts "a:b:o:" OPT; do
    case $OPT in
        a)
            act_hop=$OPTARG
            ;;
        b)
            bact_hop=$OPTARG
            ;;
        o)
            outfile=$OPTARG
            ;;
        ?)
            usage
            ;;
    esac
done

if [[ (! -e $act_hop || $act_hop == "") && (! -e $bact_hop || $bact_hop == "") ]]; then

 usage

fi


R --no-save --no-restore-data --no-restore-history --slave --quiet << EOF
library(ggplot2)
options(scipen = 999)
theme_set(theme_bw() + theme(text = element_text(size = 20, family = "Times")))

if(file.access("$act_hop") == -1) {
  act_hop <- data.frame(matrix(0, nrow=1, ncol=6))
  colnames(act_hop) = c('V1','V2','V3','V4','type','color')
} else {
  act_hop <- read.csv("$act_hop",header=F, sep='')
  colnames(act_hop) = c('V1','V2','V3','V4')
  act_hop <- cbind(act_hop,type="Electric",color="Blue")
}

if(file.access("$bact_hop") == -1) {
  bact_hop <- data.frame(matrix(0, nrow=1, ncol=6))
  colnames(bact_hop) = c('V1','V2','V3','V4','type','color')
} else {
  bact_hop <- read.csv("$bact_hop",header=F, sep='')
  colnames(bact_hop) = c('V1','V2','V3','V4')
  bact_hop <- cbind(bact_hop,type="Gas / Water",color="Purple")
}
hop <- rbind(act_hop,bact_hop)
hop <- subset(hop,V2>0)
#print(hop)
png("$outfile", width = 1200, height = 800)
  ggplot((hop),aes(x=V1,y=V2)) +
  geom_bar(stat ="identity") +
  facet_wrap( ~ type, scales = "free_y", ncol = 1) +
  labs(x= 'Mesh Hops' , y= 'Meter Counts', title = 'Distribution Of Hops')

q()
EOF

