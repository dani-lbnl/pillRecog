#Processing the features from FindPill_ISVC2015.ijm
#Dani Ushizima - dani.lbnl@gmail.com
#

require(gdata)

#my outputs from the image processing
pathOutput = "/Users/ushizima/pill/test/feat/";
pathConsolidated = "/Users/ushizima/pill/";
listOfFiles = list.files(pathOutput,pattern="xls");

#concatenate all the measurements in a single file and add filename as the last column
goodfiles = NULL
bugfiles = NULL
for (i in 1:length(listOfFiles)){
      #print(i);
      f=file.info(paste(pathOutput,listOfFiles[i],sep=''))
      
      if(f$size>200){
        xlsContent = read.table(paste(pathOutput,listOfFiles[i],sep=''),header=T)
        sample = cbind(xlsContent, listOfFiles[i])
        goodfiles = rbind(goodfiles,sample); 
      }else{
        bugfiles=cbind(bugfiles,listOfFiles[i])
      }
        
}


#Just in case R crashes, which happened before
#-fix file names
classes = as.character(goodfiles[,34])
classes = sapply(classes,function(x) paste(substr(x,1,nchar(x)-3),'jpg',sep=''))
goodfiles[,34]=classes;
names(goodfiles)[34]='pillName'
  
write.csv(goodfiles, file=paste(pathConsolidated,"goodfiles.csv",sep=''), row.names=F);
write.csv(bugfiles, file=paste(pathConsolidated,"bugfiles.csv",sep=''),row.names=F);
if (is.null(bugfiles))
  print("Happy day - no bugs!")

#Clustering process
require(car)
#Checking shape descriptors
k = 4
subg = goodfiles[,c(19,31,32,33)]
scatterplotMatrix(subg,main="Shape")
kmeansSubg = kmeans(subg, k, iter.max=100);
plot(subg, col = kmeansSubg$cluster)

result = cbind(cl$cluster,goodfiles[34]) #34 are the filenames
for(i in 1:k){
  #create a tile folder
  #fix filename
  #create tiles for that class
  #create mosaic
}
