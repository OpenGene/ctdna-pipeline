# replace path/to/XXX with your correct paths

# read filtering to get good reads with AfterQC (if you have installed pypy, replace python with pypy)
python AfterQC/after.py -1 path/to/data/R1.fq.gz -2 path/to/data/R2.fq.gz -g outdir/ -b outdir/ -r outdir/

# alignment
bwa mem -k 32 -t 10 -M hg19.fa outdir/R1.good.fq outdir/R2.good.fq > outdir/test.sam

# convert sam to bam, and sort it
samtools view -bS -@ 10 outdir/test.sam -o outdir/test.bam
samtools sort -@ 10 outdir/test.bam -f outdir/test.sort.bam

# deduplication
python dedup/dedup.py -1 outdir/test.sort.bam -o outdir/test.dedup.bam

# index bam
samtools index outdir/test.dedup.bam

# generate mpileup
# target.bed is a BED file describing the target capturing regions
samtools mpileup -B -Q 20 -C 50 -q 20 -d 20000 -f hg19.fa -l target.bed  outdir/test.dedup.bam >outdir/test.dedup.mpileup

# SNP calling with VarScan
java -jar VarScan.v2.3.8.jar mpileup2snp outdir/test.dedup.mpileup --min-coverage 4 --min-reads2 2 --min-avg-qual 20 --min-var-freq 0.001 --min-freq-for-hom 90 --output-vcf 1 > outdir/test.snp.vcf

# INDEL calling with VarScan
java -jar VarScan.v2.3.8.jar mpileup2indel outdir/test.dedup.mpileup --min-coverage 4 --min-reads2 2 --min-avg-qual 20 --min-var-freq 0.001 --min-freq-for-hom 90 --output-vcf 1 > outdir/test.indel.vcf

# Annovar annotation
table_annovar.pl outdir/test.snp.vcf path/to/annovar/humandb/ -buildver hg19 -out outdir/test.snp -remove -protocol refGene,cytoBand,genomicSuperDups,esp6500siv2_all,1000g2014oct_all,1000g2014oct_afr,1000g2014oct_eas,1000g2014oct_eur,snp138,ljb26_all,cosmic77,clinvar_20160302 -operation g,r,r,f,f,f,f,f,f,f,f,f -nastring . -vcfinput
table_annovar.pl outdir/test.indel.vcf path/to/annovar/humandb/ -buildver hg19 -out outdir/test.indel -remove -protocol refGene,cytoBand,genomicSuperDups,esp6500siv2_all,1000g2014oct_all,1000g2014oct_afr,1000g2014oct_eas,1000g2014oct_eur,snp138,ljb26_all,cosmic77,clinvar_20160302 -operation g,r,r,f,f,f,f,f,f,f,f,f -nastring . -vcfinput

# Mutated Reads counting with MrBam
export PYTHONPATH=path/to/mrbam/:${PYTHONPATH}
python3 -m MrBam.main -o outdir/test.snp_MrBam.txt -m 3 -q 25 --fast --cfdna outdir/test.dedup.bam --skip 1 outdir/test.snp.hg19_multianno.txt
python3 -m MrBam.main -o outdir/test.indel_MrBam.txt -m 3 -q 25 --fast --cfdna outdir/test.dedup.bam --skip 1 outdir/test.indel.hg19_multianno.txt

# SNP/INDEL filtering
perl Filter.pl outdir/test.snp_MrBam.txt outdir/test.snp_MrBam.filter 2 0.3
perl Filter.pl outdir/test.indel_MrBam.txt outdir/test.indel_MrBam.filter 2 0.3

# check for important drugable mutations by MutScan
MutScan/mutscan -1 path/to/data/R1.fq.gz -2 path/to/data/R2.fq.gz -h outdir/test_mutscan.html

# check for important drugable mutations by GeneFuse
GeneFuse/genefuse -1 path/to/data/R1.fq.gz -2 path/to/data/R2.fq.gz -r hg19.fa -f GeneFuse/genes/cancer.hg19.csv -h outdir/test_genefuse.html

python3 -m MrBam.main -o outdir/test.snp_MrBam.txt -m 3 -q 25 --fast --cfdna outdir/test.dedup.bam --skip 1 outdir/test.snp.hg19_multianno.txt 
python3 -m MrBam.main -o outdir/test.snp_MrBam.txt -m 3 -q 25 --fast --cfdna outdir/test.dedup.bam --skip 1 outdir/test.snp.hg19_multianno.txtc
python3 -m MrBam.main -o outdir/test.snp_MrBam.txt -m 3 -q 25 --fast --cfdna outdir/test.dedup.bam --skip 1 outdir/test.snp.hg19_multianno.txt
