source('F:/Prosjekter/Kommunehelsa/PRODUKSJON/BIN/KHfunctions_20200430.R')  #krever nye pakker

pkg <- c("RODBC", "DBI", "data.table", "glue", "fs", "logger", "magrittr")
sapply(pkg, require, character.only = TRUE)


## aar <- 2020
godkjent <- function(profil = c("FHP", "OVP"),
                     modus = globglobs$KHgeoniv,
                     aar = globglobs$KHaar, ...){

  cat(paste0("\n********\n  Flytt av filer for ",
             profil[1], " og geonivå ", modus, " for ",
             aar, " begynner nå\n********\n" ))

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

  ## filter data
  utTYP <- profil[1]

  tblAlle <- rawAlle[PROFILTYPE == utTYP, ] %>%
    .[MODUS == modus, ] %>%
    .[OK_PROFILAAR_GEO == 1, ]


  ## Create filenames
  fileNames <- tblAlle[, filename := paste0(INDIKATOR, "_", VERSJON_PROFILAAR_GEO, ".csv")][["filename"]]

  ## Root folder where the file is
  pathRoot <- defpaths[1]

  ## Path for Profile
  pathProfil <- switch(utTYP,
                       "FHP" = c(
                         globglobs$FriskVDir_F,
                         globglobs$FriskVDir_K,
                         globglobs$FriskVDir_B
                       ),
                       "OVP" = c(
                         globglobs$ovpDir_F,
                         globglobs$ovpDir_K,
                         globglobs$ovpDir_B
                       ))


  ## Geolevels
  modeProfil <- c("F", "K", "B")
  indMode <- grep(modus, modeProfil, ignore.case = TRUE)

  ## Get correct path to profil
  pathDir <- pathProfil[indMode]

  ## Current date style to create folder
  batchdate<-SettKHBatchDate()

  fileRoot <- paste0(pathRoot, "/", pathDir, aar)
  fileFrom <- file.path(fileRoot, "CSV")
  fileTo <- file.path(fileRoot, "GODKJENT", batchdate)

  ## Check if folder exists else create
  if (!fs::dir_exists(fileTo)) fs::dir_create(fileTo)

  ## fileComplete <- sapply(fileNames, function(x) file.path(fileFrom, x))

  fileOK <- list()
  fileKO <- list()

  for (i in fileNames){

    outFile <- file.path(fileFrom, i)
    inFile <- file.path(fileTo, i)

    outMsg <- tryCatch(
    {fs::file_copy(outFile, inFile, overwrite = TRUE)},
    error = function(err) err)

    if (inherits(outMsg, "error")){
      message(paste0("\n--> OPS! Finner ikke filen: ", i, "\n"))
      fileKO[i] <- i
      next
    } else {
      message(paste0("Kopierer filen: ", i))
      fileOK[i] <- i
    }

  }

  cat(paste0("\n**********\n", " ",
             length(fileOK),
             " filer ble flyttet til ",
             fileTo, "\n"))

  cat(paste0("----------\n", " ",
             length(fileKO),
             " filer finnes ikke i ",
             fileFrom, "\n**********\n"))
}
