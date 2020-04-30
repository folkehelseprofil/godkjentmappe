source('F:/Prosjekter/Kommunehelsa/PRODUKSJON/BIN/KHfunctions_20200103.r')  #krever nye pakker

KHaar<-2020
modus<-"K"

globs<-SettGlobs(modus="KH")
GodkjenteKuberTabell<-paste("KH",KHaar,"_KUBESTATUS",sep="")
#FriskvikFiler<-paste("FRISKVIK",KHaar,sep="")
FriskvikFiler<-"FRISKVIK"



library(RODBC)
mdb_file <- file.path(defpaths[1], globglobs$KHdbname)
conn <- odbcDriverConnect(paste0("Driver={Microsoft Access Driver (*.mdb, *.accdb)};DBQ=",
                                 mdb_file))

## ## kubeTBL
## tbl_friskvik <- sqlFetch(conn, "FRISKVIK")
## tbl_kubestatus <- sqlFetch(conn, GodkjenteKuberTabell)


library(glue)
tblCols <- c("PROFILTYPE", "INDIKATOR", "KUBE_NAVN", "MODUS", "AARGANG")
tblName <- "FRISKVIK"
sqlFrisk <- glue_sql("SELECT {`tblCols`*}
                      FROM {`tblName`}
                      WHERE {`tblCols[5]`} = {KHaar}", .con = DBI::ANSI())

tbl_fsk <- sqlQuery(conn, sqlFrisk)

tblCols <- c("KUBE_NAVN", "VERSJON_PROFILAAR_GEO", "OK_PROFILAAR_GEO")
tblName <- paste0("KH", KHaar, "_KUBESTATUS")
sqlKube <- glue_sql("SELECT {`tblCols`*} from {`tblName`}", .con = DBI::ANSI())

tbl_kube <- sqlQuery(conn, sqlKube)

library(data.table)
invisible(sapply(list(tbl_fsk, tbl_kube), setDT))



## merge tabels
rawAlle <- tbl_fsk[tbl_kube, on = "KUBE_NAVN"]

## filter more
utTYP <- "FHP"
utMDS <- "K"
utOK <- 1

tblAlle <- rawAlle[PROFILTYPE == utTYP, ] %>%
   .[MODUS == utMDS, ] %>%
   .[OK_PROFILAAR_GEO == utOK, ]


## Create filenames
fileNames <- tblAlle[, filename := paste0(INDIKATOR, "_", VERSJON_PROFILAAR_GEO, ".csv")][["filename"]]

library(fs)

## Root folder where the file is
pathRoot <- defpaths[1]
pathDir <- globglobs$FriskVDir_K
KHaar

batchdate<-SettKHBatchDate()

rootPath <- paste0(pathRoot, "/", pathDir, KHaar)
fileFrom <- file.path(rootPath, "CSV")
fileTo <- file.path(rootPath, "GODKJENT", batchdate)

## fileComplete <- sapply(fileNames, function(x) file.path(fileFrom, x))
library(logger)

for (i in fileNames){
  outFile <- file.path(fileFrom, i)
  inFile <- file.path(fileTo, i)
  logger::log_info(paste0("Filnavn: ", i))
  ## logger::log_info(paste0("Flytt fil: ", outFile))
  ## logger::log_info(paste0("Legges til: ", inFile))
  ## fs::file_copy(path, new_path, overwrite = FALSE)
}

cat(paste0("\n*********\n Alle filer er kopiert til denne mappen:\n ",
           fileTo, "/\n*********\n"))



odbcCloseAll()



## ## Test for speed
## library(microbenchmark)
## microbenchmark(

##   tbl_friskvik <- sqlFetch(conn, "FRISKVIK"),
##   df <- dplyr::tbl(conn2, "FRISKVIK") %>%
##   dplyr::collect()

## )


##   FriskVDir_F="PRODUKTER/KUBER/FRISKVIK_FYLKE/",
##   FriskVDir_K="PRODUKTER/KUBER/FRISKVIK_KOMM/",
##   FriskVDir_B="PRODUKTER/KUBER/FRISKVIK_BYDEL/",
##   ovpDir_F="PRODUKTER/KUBER/OVP_FYLKE/",
##   ovpDir_K="PRODUKTER/KUBER/OVP_KOMM/",
##   ovpDir_B="PRODUKTER/KUBER/OVP_BYDEL/",
