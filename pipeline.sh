# replace path/to/XXX with your correct paths

# read filtering to get good reads with AfterQC
python AfterQC/after.py --no_correction -1 path/to/data/R1.fq.gz -2 path/to/data/R2.fq.gz -g outdir/ -b outdir/ -r outdir/

# alignment
bwa mem -k 32 -t 10 -M hg19.fa outdir/R1.good.fq outdir/R2.good.fq > outdir/Test.sam

# convert sam to bam, and sort it
samtools view -bS -@ 10 outdir/Test.sam -o outdir/Test.bam
samtools sort -@ 10 outdir/Test.bam -f outdir/Test.sort.bam

# deduplication
python dedup/dedup.py -1 outdir/Test.sort.bam -o outdir/Test.dedup.bam

# index bam
samtools index outdir/Test.dedup.bam

# generate mpileup
samtools mpileup -B -Q 20 -C 50 -q 20 -d 20000 -f /thinker/net/ctDNA/WES_ref/hg19.fa -l data/CancerDrugV2_Roche.bed  outdir/Test.dedup.bam >outdir/Test.dedup.mpileup

# SNP calling with VarScan
java -jar VarScan.v2.3.8.jar mpileup2snp outdir/Test.dedup.mpileup --min-coverage 4 --min-reads2 2 --min-avg-qual 20 --min-var-freq 0.001 --min-freq-for-hom 90 --output-vcf 1 > outdir/Test.snp.vcf

# INDEL calling with VarScan
java -jar VarScan.v2.3.8.jar mpileup2indel outdir/Test.dedup.mpileup --min-coverage 4 --min-reads2 2 --min-avg-qual 20 --min-var-freq 0.001 --min-freq-for-hom 90 --output-vcf 1 > outdir/Test.indel.vcf

# Annovar annotation
table_annovar.pl outdir/Test.snp.vcf path/to/annovar/humandb/ -buildver hg19 -out outdir/Test.snp -remove -protocol refGene,cytoBand,genomicSuperDups,esp6500siv2_all,1000g2014oct_all,1000g2014oct_afr,1000g2014oct_eas,1000g2014oct_eur,snp138,ljb26_all,cosmic77,clinvar_20160302 -operation g,r,r,f,f,f,f,f,f,f,f,f -nastring . -vcfinput
table_annovar.pl outdir/Test.indel.vcf path/to/annovar/humandb/ -buildver hg19 -out outdir/Test.indel -remove -protocol refGene,cytoBand,genomicSuperDups,esp6500siv2_all,1000g2014oct_all,1000g2014oct_afr,1000g2014oct_eas,1000g2014oct_eur,snp138,ljb26_all,cosmic77,clinvar_20160302 -operation g,r,r,f,f,f,f,f,f,f,f,f -nastring . -vcfinput

# Mutated Reads counting with MrBam
export PYTHONPATH=path/to/mrbam/:${PYTHONPATH}
python3 -m MrBam.main -o outdir/Test.snp_MrBam.txt -m 3 -q 25 --fast --cfdna outdir/Test.dedup.bam --skip 1 outdir/Test.snp.hg19_multianno.txt
python3 -m MrBam.main -o outdir/Test.indel_MrBam.txt -m 3 -q 25 --fast --cfdna outdir/Test.dedup.bam --skip 1 outdir/Test.indel.hg19_multianno.txt

# SNP/INDEL filtering
perl Filter.pl outdir/Test.snp_MrBam.txt outdir/Test.snp_MrBam.filter 2 0.3
perl Filter.pl outdir/Test.indel_MrBam.txt outdir/Test.indel_MrBam.filter 2 0.3

# check for important drugable mutations by MutScan
mutscan -1 data/Test_R1.fq -2 data/Test_R2.fq -h outdir/Test_mutscan.html