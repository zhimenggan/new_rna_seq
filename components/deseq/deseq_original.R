if(!require("DESeq", character.only=T)) stop("Please install the DESeq package first.")
if(!require("RColorBrewer", character.only=T)) stop("Please install the RColorBrewer package first.")
if(!require("gplots", character.only=T)) stop("Please install the gplots package first.")

# get args from the commandline:

args<-commandArgs(TRUE)
RAW_COUNT_MATRIX<-args[1]
SAMPLE_ANNOTATION_FILE<-args[2]
CONDITION_A<-args[3]
CONDITION_B<-args[4]
OUTPUT_DESEQ_FILE <- args[5] #full path
OUTPUT_HEATMAP_FILE <- args[6] #full path
NUM_GENES<-as.integer(args[7])

# read the raw count matrix:
count_data <- read.table(RAW_COUNTS_FILE, sep='\t', header = T)

# save the gene names for later and remove that column of the dataframe
gene_names <- count_data[,1]
count_data<-count_data[-1]

# read the annotations and get the conditions in the same order as the columns of the count_data dataframe
annotations <- read.table(SAMPLE_ANNOTATION_FILE, sep='\t', header = F, row.names=1)
annotations <- annotations[colnames(count_data),]

#run the DESeq steps:
cds=newCountDataSet(count_data, annotations)
cds=estimateSizeFactors(cds)
cds=estimateDispersions(cds)
res=nbinomTest(cds, CONDITION_A, CONDITION_B)

#write the differential expression results to a file:
write.csv(as.data.frame(res), file=OUTPUT_DESEQ_FILE, row.names=FALSE)


######### For creating contrast-level heatmap ######################

#produce a heatmap of the normalized counts, using the variance-stabilizing transformation:
cdsFullBlind<-estimateDispersions(cds, method="blind")
vsdFull<-varianceStabilizingTransformation(cdsFullBlind)

nc<-counts( cds, normalized=TRUE )
select<-order(res$padj)[1:NUM_GENES]
heatmapcols<-colorRampPalette(brewer.pal(9, "GnBu"))(100)

#set the longest dimension of the image:
shortest_dimension<-1200 #pixels
sample_count<-ncol(vsdFull)
ratio<-0.25*NUM_GENES/sample_count

#most of the time there will be more genes than samples
#set the aspect ratio of the heatmap accordingly
h<-shortest_dimension*ratio
w<-shortest_dimension

#however, if more samples than genes, switch the dimensions so it looks reasonable:
if (ratio < 1)
{
	temp<-w
	w<-h
	h<-temp
}

# adjust the text size to be reasonable with the size of the heatmap
text_size = 1.5+1/log10(NUM_GENES)

#write the heatmap as a png:
png(filename=OUTPUT_HEATMAP_FILE, width=w, height=h, units="px")
heatmap.2(exprs(vsdFull)[select,], col=heatmapcols, trace="none", margin=c(25,12), cexRow=text_size, cexCol=text_size)
dev.off()

