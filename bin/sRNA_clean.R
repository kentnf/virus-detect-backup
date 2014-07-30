#trimReadʵ���в���,���Կ����ר��
trimRead <- function(fastqfile, trimmed_file, null_file, trimmed3End_file, unmatched_file, mismatch= 0.1, PCR2rc)
{

	reads <- readFastq(fastqfile);#����FASTQ�ļ�
	seqs <- sread(reads); # ȡ�����м�¼��read����sequence��Ϣ,���ݸ�ʽDNAStringSet	
	rawLength <- max(width(reads));# �õ�ԭʼ������reads����
	lineofresult <- c(fastqfile, rawLength, length(reads))#�ռ�3����Ϣ,�����ļ����ơ�reads���Ⱥ�reads����
	
	#ȥ��reads�к��еĲ��ֻ�����PCR2rc/adapter
	trimmedCoords <- trimLRPatterns(Rpattern = PCR2rc, subject = seqs, max.Rmismatch= mismatch, with.Rindels=T,ranges=T)#����õ�����
	trimmedReads <- narrow(reads, start=start(trimmedCoords), end=end(trimmedCoords))#������һ���õ������꣬ͬʱtrim���������к�������������	
	trimmed3End <- narrow(reads, start=end(trimmedCoords)+1, end=width(reads))#��trimm�����ǲ������б������Ա��˹����
	rm(trimmedCoords)
	writeFastq(trimmed3End, file=trimmed3End_file)      	
	rm(trimmed3End)
	
	unmatchedReads <- trimmedReads[width(trimmedReads)==width(reads)[1]]#����ȫ����reads����ʾunmatched
	writeFastq(unmatchedReads, file= unmatched_file)
	unmatched_length <- length(unmatchedReads)
	rm(unmatchedReads)
	nullReads <- trimmedReads[width(trimmedReads)==0]#�����reads����ʾnull
	writeFastq(nullReads, file= null_file)
	null_length <- length(nullReads)
	rm(nullReads)
	trimmedReads <- trimmedReads[width(trimmedReads)<width(reads)[1]]#�����ȫ����reads����ʾtrimmed
	trimmedReads <- trimmedReads[width(trimmedReads)>0]#ȥ�������еĿ�����
	writeFastq(trimmedReads, file=trimmed_file)
	lineofresult <- c(lineofresult, length(trimmedReads),null_length,unmatched_length)#����1�У�trimmedReads������
	write(lineofresult,file = "trimmed.report", ncolumns =7,append = T, sep = "\t")
	rm(trimmedReads)
	gc()
}

cleanRead <- function(fastqfile, cleaned_file, nCutoff=1, readLength=15, RdPerYield){
	#reads <- readFastq(fastqfile);#����FASTQ�ļ�
	inFh <- FastqStreamer(fastqfile, n=RdPerYield); 
	if (file.exists(cleaned_file) ) {file.remove(cleaned_file); } #�������ļ��Ѿ����ڱ���ɾ������ֹ׷��д
	iteration=0;
	trimmed_reads=0;
	cleaned_reads=0;
	trimmed_len=0;
	cleaned_len=0;
	while (length(reads <- yield(inFh))) { #ÿ�ο��ƶ���5�����reads
		seqs <- sread(reads); # ȡ�����м�¼��read����sequence��Ϣ,���ݸ�ʽDNAStringSet		
		nCount<-alphabetFrequency(seqs)[,"N"];#ͳ��ÿ��read�е��ַ�N����,
		rm(seqs);#���꼰ʱɾ��		
		trimmed_reads <- trimmed_reads + length(reads);#�ۼ�trimmed��reads������
		trimmed_len=trimmed_len+sum(width(reads));#�ۼ�trimmed reads���ܳ���		
		cleanedReads<-reads[nCount<nCutoff];#ֻ�����ַ�N����<nCutoff��reads
		rm(reads);
		cleanedReads <- cleanedReads[width(cleanedReads)>=readLength];#ȥ������һ�����ȣ�Ĭ����15bp����reads
		writeFastq(cleanedReads, file=cleaned_file, mode="a", full=FALSE);#����cleaned������,ע����׷��д
		cleaned_reads <- cleaned_reads + length(cleanedReads);#�ۼ�cleaned��reads������
		cleaned_len=cleaned_len+sum(width(cleanedReads));#�ۼ�cleaned reads���ܳ���
		rm(cleanedReads);
		gc();
	}#End yield while;
	close(inFh);
	trimmed_len=trimmed_len/trimmed_reads;#�õ�trimmed reads��ƽ������
	cleaned_len=cleaned_len/cleaned_reads;#�õ�cleaned reads��ƽ������
	lineofresult <- c(fastqfile, trimmed_reads, trimmed_len, cleaned_reads, cleaned_len);
	write(lineofresult,file = "cleaned.report", ncolumns =5,append = T, sep = "\t");
}