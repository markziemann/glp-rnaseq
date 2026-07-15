#!/bin/bash
set -x


# Reference transcriptome setup GENCODE Mouse Release M38 (GRCm39)

# FASTQC
ls | grep fq.gz$ | parallel -j4 fastqc -t 4 {}
# MULTIQC
multiqc .

IDX=../ref/gencode.vM38.transcripts.fa.idx

for FQZ1 in *_1.fq.gz ; do
  FQZ2=$(echo $FQZ1 | sed 's#_1.#_2.#')
  echo $FQZ1 $FQZ2
  skewer -q 20 -t 16 $FQZ1 $FQZ2
  FQT1=$(echo $FQZ1 | sed 's#fq.gz#fq-trimmed-pair1.fastq#')
  FQT2=$(echo $FQZ1 | sed 's#fq.gz#fq-trimmed-pair2.fastq#')
  BASE=$(echo $FQZ1 | cut -d '_' -f1)
  kallisto quant -o $BASE -i $IDX -t 16 $FQT1 $FQT2
  rm $FQT1 $FQT2
done

for TSV in $(find . | grep abundance.tsv$) ; do
  NAME=$(echo $TSV | cut -d '/' -f2 )
  cut -f1,4 $TSV | sed 1d | sed "s/^/${NAME}\t/"
done | pigz > 3col.tsv.gz
