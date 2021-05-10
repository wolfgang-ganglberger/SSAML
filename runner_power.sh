#!/bin/bash

# constants
p=`pwd`
localMAC=0

runMode=$1
dataTYPE=$2


if [[ $localMAC -eq 1 ]]; then
    infile='/myfiles/inputDataFile.csv'
    outdir='/myfiles/dir_for_outputs'
else
    if [[ $dataTYPE -eq 0 ]]; then
        infile='/home/dmg16/deepMan/OUTPUT_for_paper/holdoutisThisReal_v2.csv'
        outdir='/home/dmg16/SSAML/OUTst'
        peopleTF=1
        survivalTF=0
        maxlist='20 40 60 80'
    elif [[ $dataTYPE -eq 1 ]]; then
        infile='/home/dmg16/SSAML/risk_7day-simplified.csv'
        outdir='/home/dmg16/SSAML/OUTcova'
        peopleTF=0
        survivalTF=0
        maxlist='125 150 175 200'
    elif [[ $dataTYPE -eq 2 ]]; then
        infile='/home/dmg16/SSAML/BA_For_Daniel.csv'
        outdir='/home/dmg16/SSAML/OUTbai'
        peopleTF=1
        survivalTF=1
        maxlist='200 500 1000 1500'
    else
        echo "Error. No datatype specified."
        exit 1
    fi
fi

conflist='0.955 0.997 0.9999 0.999999'
ilist=`seq 0 1 24`
iterNumber=0
case $runMode in
    1)
        # This is runMode 1 - submit batches of scripts here (several hours)
        runMode=1
        mkdir -p $outdir/holder
        mkdir -p $outdir/theZING
        for confint in $conflist; do
            for maxPts in $maxlist; do
                for iterNumber in $ilist; do       
                    if [[ $dataTYPE -eq 0 ]]; then
                        sbatch run_power.sh $runMode $dataTYPE $iterNumber $maxPts $confint $infile $outdir $peopleTF $survivalTF
                    else
                        ./run_power.sh $runMode $dataTYPE $iterNumber $maxPts $confint $infile $outdir $peopleTF $survivalTF
                    fi
                done
            done
        done
        cd $outdir
        echo $conflist > conflist.setup
        ;;
    2)
        runMode=2
        cd $outdir
        for confint in $conflist; do
            for maxPts in $maxlist; do
                maxP=`printf "%04d" $maxPts`
                FILE=num${maxP}_${confint}.csv
                if [ ! -f "$FILE" ]; then
                    cat num${maxP}????_${confint}.csv > $FILE
                    mv num${maxP}????_${confint}.csv holder/
                fi
                echo "python $p/power.py $runMode $dataTYPE $iterNumber $maxPts $confint $infile $outdir $peopleTF $survivalTF"
                python $p/power.py $runMode $dataTYPE $iterNumber $maxPts $confint $infile $outdir $peopleTF $survivalTF
                fullResultName="full${maxP}_${confint}.csv"
                head -n 1 $fullResultName >> RWD_${confint}.txt
                head -n 2 $fullResultName | tail -n 1 >> BIAS_${confint}.txt
                tail -n 1 $fullResultName >> COVP_${confint}.txt
                FILE=smallZ${maxP}.csv
                if [ ! -f "$FILE" ]; then
                    cat ZINGnum${maxP}????_*.csv > $FILE
                    mv ZINGnum${maxP}????_*.csv theZING/
                fi
            done    
        done
        runMode=3
        maxPts=0
        confint=0
        python $p/power.py $runMode $dataTYPE $iterNumber $maxPts $confint $infile $outdir $peopleTF $survivalTF
        ;;
    3)
        runMode=3
        cd $outdir
        maxPts=0
        confint=0
        python $p/power.py $runMode $dataTYPE $iterNumber $maxPts $confint $infile $outdir $peopleTF $survivalTF
        ;;
    *)
        ;;
esac




