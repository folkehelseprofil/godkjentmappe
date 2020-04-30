# FØR KJØRING:
  # Sjekk profilårgang i "KHaar" nedenfor.
  # Sjekk datotag (versjon) for KHfunctions i source-kommandoen.


# F:\Prosjekter\Kommunehelsa\PRODUKSJON\PRODUKTER\KUBER\FRISKVIK_BYDEL\2018\GODKJENT\
# Scriptet leser fra tabell xH20XX_KUBESTATUS hvilke kuber som er godkjent, og 
# kopierer deres Friskvikfiler til en nyopprettet mappe under ovenstående,
# navngitt med datotag for kjøringstidspunktet.

# ENDRINGER:
# stbj 10.10.2019: Endret feltnavn i KHxxxx_KUBESTATUS. I sqlQuery-kommandoen:
#   VERSJON heter nå VERSJON_PROFILAAR_GEO, og OK heter nå OK_PROFILAAR_GEO.
#   (Oppdaget at feltnavn ikke kan inneholde bindestrek...)
# stbj 24.04.2020: Lagt inn filter på Profiltype=FHP ifm. tilrettelegging for Oppvekstprofiler.
#   PLUSS at scriptet selv oppretter mappen /GODKJENT/ for ny årgang.

args <- commandArgs(trailingOnly = TRUE)
source('F:/Prosjekter/Kommunehelsa/PRODUKSJON/BIN/KHfunctions.r')
if (grepl("\\S",args[1])){
  batchdate<-args[1]
} else {
  batchdate<-SettKHBatchDate()
}

KHaar<-2019
modus<-"B"

globs<-SettGlobs(modus="KH")
GodkjenteKuberTabell<-paste("KH",KHaar,"_KUBESTATUS",sep="")
#FriskvikFiler<-paste("FRISKVIK",KHaar,sep="")
FriskvikFiler<-"FRISKVIK"

# FriskvikBatch<-sqlQuery(globs$dbh,paste("SELECT INDIKATOR & '_' & VERSJON 
#                                     FROM ",FriskvikFiler," LEFT JOIN ", GodkjenteKuberTabell, 
#                                         " ON ", FriskvikFiler,".KUBE_NAVN = ",GodkjenteKuberTabell,".KUBE_NAVN
#                                         WHERE MODUS='",modus,"' AND OK = '1'  AND AARGANG=",KHaar,sep=""),as.is=TRUE)

FriskvikBatch<-sqlQuery(globs$dbh,paste("SELECT INDIKATOR & '_' & VERSJON_PROFILAAR_GEO
                                    FROM ",FriskvikFiler," LEFT JOIN ", GodkjenteKuberTabell,
                                        " ON ", FriskvikFiler,".KUBE_NAVN = ",GodkjenteKuberTabell,".KUBE_NAVN
                                        WHERE PROFILTYPE='FHP' AND MODUS='",modus,"'
                                          AND OK_PROFILAAR_GEO = '1' AND AARGANG=",KHaar,sep=""),as.is=TRUE)

dir.create(paste(globs$path,"/",globs$FriskVDir_B,"/",KHaar,"/GODKJENT",sep=""))
newdir<-paste(globs$path,"/",globs$FriskVDir_B,"/",KHaar,"/GODKJENT/",batchdate,sep="")
dir.create(newdir)

for (i in 1:nrow(FriskvikBatch)){
  orgfil<-paste(globs$path,"/",globs$FriskVDir_B,"/",KHaar,"/CSV/",FriskvikBatch[i,1],".csv",sep="")
  kopi<-paste(newdir,"/",FriskvikBatch[i,1],".csv",sep="")
  print(orgfil)
  print(kopi)
  file.copy(orgfil,kopi)
}
