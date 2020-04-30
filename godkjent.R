## source('F:/Prosjekter/Kommunehelsa/PRODUKSJON/BIN/KHfunctions_20200103.r')  #krever nye pakker

pkg <- c("RODBC", "DBI", "data.table", "glue", "fs", "logger", "magrittr")
sapply(pkg, require, character.only = TRUE)

## aar <- 2020
godkjent <- function(profil = c("FHP", "OVP"),
                     modus = globglobs$KHgeoniv,
                     aar = globglobs$KHaar, ...){

  extra <- list(...)

  ## Get connection to DB
  mdb_file <- file.path(defpaths[1], globglobs$KHdbname)
  conn <- RODBC::odbcDriverConnect(paste0("Driver={Microsoft Access Driver (*.mdb, *.accdb)};DBQ=",
                                 mdb_file))

  tblCols <- c("PROFILTYPE", "INDIKATOR", "KUBE_NAVN", "MODUS", "AARGANG")
  tblName <- "FRISKVIK"
  sqlFrisk <- glue::glue_sql("SELECT {`tblCols`*}
                      FROM {`tblName`}
                      WHERE {`tblCols[5]`} = {aar}", .con = DBI::ANSI())

  tbl_fsk <- RODBC::sqlQuery(conn, sqlFrisk)

  tblCols <- c("KUBE_NAVN", "VERSJON_PROFILAAR_GEO", "OK_PROFILAAR_GEO")
  tblName <- paste0("KH", aar, "_KUBESTATUS")
  sqlKube <- glue::glue_sql("SELECT {`tblCols`*} from {`tblName`}", .con = DBI::ANSI())

  tbl_kube <- RODBC::sqlQuery(conn, sqlKube)

  invisible(sapply(list(tbl_fsk, tbl_kube), setDT))

  ## merge tabels
  rawAlle <- tbl_fsk[tbl_kube, on = "KUBE_NAVN"]

  ## filter more
  utTYP <- profil[1]
  utMDS <- modus
  utOK <- 1

  tblAlle <- rawAlle[PROFILTYPE == utTYP, ] %>%
    .[MODUS == utMDS, ] %>%
    .[OK_PROFILAAR_GEO == utOK, ]


  ## Create filenames
  fileNames <- tblAlle[, filename := paste0(INDIKATOR, "_", VERSJON_PROFILAAR_GEO, ".csv")][["filename"]]

  ## Root folder where the file is
  pathRoot <- defpaths[1]
  pathDir <- globglobs$FriskVDir_K


  batchdate<-SettKHBatchDate()

  rootPath <- paste0(pathRoot, "/", pathDir, aar)
  fileFrom <- file.path(rootPath, "CSV")
  fileTo <- file.path(rootPath, "GODKJENT", batchdate)

  ## Check if folder exists
  if (!fs::dir_exists(fileTo)) fs::dir_create(fileTo)

  ## fileComplete <- sapply(fileNames, function(x) file.path(fileFrom, x))

  for (i in fileNames){
    outFile <- file.path(fileFrom, i)
    inFile <- file.path(fileTo, i)
    logger::log_info(paste0("Filnavn: ", i))
    fs::file_copy(path, new_path, overwrite = FALSE)
  }

  cat(paste0("\n*********\n", length(fileNames), " filer er kopiert til denne mappen:\n ",
             fileTo, "/\n*********\n"))
}

## odbcCloseAll()
