args <- commandArgs(trailingOnly = TRUE)
source('F:/Prosjekter/Kommunehelsa/PRODUKSJON/BIN/KHfunctions.r')
if (grepl("\\S",args[1])){
  batchdate<-args[1]
} else {
  batchdate<-SettKHBatchDate()
}

KHaar<-2016
globs<-SettGlobs(modus="KH")
GodkjenteKuberTabell<-paste("KH",KHaar,"_KUBESTATUS",sep="")
FriskvikFiler<-paste("FRISKVIK",KHaar,sep="")

FriskvikBatch<-sqlQuery(globs$dbh,paste("SELECT INDIKATOR & '_' & VERSJON 
                                    FROM ",FriskvikFiler," LEFT JOIN ", GodkjenteKuberTabell, 
                                    " ON ", FriskvikFiler,".KUBE_NAVN = ",GodkjenteKuberTabell,".KUBE_NAVN",sep=""),as.is=TRUE)

newdir<-paste(globs$path,"/",globs$FriskVDir_K,"/",KHaar,"/GODKJENT/",batchdate,sep="")
dir.create(newdir)

for (i in 1:nrow(FriskvikBatch)){
  orgfil<-paste(globs$path,"/",globs$FriskVDir_K,"/",KHaar,"/CSV/",FriskvikBatch[i,1],".csv",sep="")
  kopi<-paste(newdir,"/",FriskvikBatch[i,1],".csv",sep="")
  print(orgfil)
  print(kopi)
  file.copy(orgfil,kopi)
}
