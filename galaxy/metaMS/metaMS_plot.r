#!/usr/local/public/bin/Rscript --vanilla --slave --no-site-file
# metams.r version="2.1.2"
#created by Yann GUITTON 
#use RI options + add try on plotUnknown add session Info
#use make.names in sampleMetadata to avoid issues with files names 


# ----- LOG FILE -----
log_file <- file("plot_metaMS.log", open = "wt")
sink(log_file)
sink(log_file, type = "output")


# ----- PACKAGE -----
cat("\tSESSION INFO\n")

#Import the different functions
source_local <- function(fname) {
    argv <- commandArgs(trailingOnly = FALSE)
    base_dir <- dirname(substring(argv[grep("--file=", argv)], 8))
    source(paste(base_dir, fname, sep="/"))
}
source_local("lib_metams.r")

pkgs <- c("metaMS","batch") #"batch" necessary for parseCommandArgs function
loadAndDisplayPackages(pkgs)

cat("\n")

modNamC <- "plot_metaMS" ## module name

cat("\nStart of the '", modNamC, "' Galaxy module call: ", 
    format(Sys.time(), "%a %d %b %Y %X"), "\n\n", sep="")


# ----- ARGUMENTS -----
cat("\tARGUMENTS INFO\n\n")
args = parseCommandArgs(evaluate=FALSE) #interpretation of arguments given in command line as an R list of objects
write.table(as.matrix(args), col.names=F, quote=F, sep='\t\t')


# ----- PROCESSING INFILE -----
cat("\n\n\tARGUMENTS PROCESSING INFO\n\n")

# Loading RData file
load(args[["metaMS"]])
if (!exists("resGC")) stop("\n\nERROR: The RData doesn't contain any object called 'resGC' which is provided by the tool: new_metaMS.runGC")

if(args[["selecteic"]]) {
    #Unknown EIC parameter
    if (args[["unkn"]][1] != "NULL") {
        #When unkn = 0 user want to process all unknowns
        if(args[["unkn"]][1] == 0) {
            args[["unkn"]] <- c(1:nrow(resGC$PeakTable))
            print("User want to process on all unknown(s) found in metaMS process")
        }
        #TODO find the biggest number of unkn ask by user cause it can write "1,15,9,8" with a max of 11 unkn. With this code it finds the 8 and it will pass
        #Verify that there is not more user's unkn than metaMS unkn (find in resGC$PeakTable)
        cat("Number of unknown after metaMS process :",nrow(resGC$PeakTable),"\n")
        cat("Number of the last unknown ask by user :",args[["unkn"]][length(args[["unkn"]])],"\n")
        cat("Number of unknown ask by user :",length(args[["unkn"]]),"\n")
        if(args[["unkn"]][length(args[["unkn"]])] <= nrow(resGC$PeakTable)) {
            unknarg <- args[["unkn"]]
        } else {
            error_message="Too much unkn compare metaMS results"
            print(error_message)
            stop(error_message)
        }
    } else {
        error_message <- "No EIC selected !"
        print(error_message)
        stop(error_message)
    }
}

cat("\n\n")


# ----- INFILE PROCESSING -----
cat("\tINFILE PROCESSING INFO\n\n")

# Handle infiles
if (!exists("singlefile")) singlefile <- NULL
if (!exists("zipfile")) zipfile <- NULL
rawFilePath <- getRawfilePathFromArguments(singlefile, zipfile, args)
zipfile <- rawFilePath$zipfile
singlefile <- rawFilePath$singlefile
directory <- retrieveRawfileInTheWorkingDirectory(singlefile, zipfile)

# ----- MAIN PROCESSING INFO -----
cat("\n\n\tMAIN PROCESSING INFO\n")


cat("\t\tCOMPUTE\n")

#TIC/BPC picture generation

#Use getTIC2s and getBPC2s because getTICs and getBPCs can exists due to transfert of function in Rdata

if(!is.null(singlefile)) {
    files <- paste("./",names(singlefile),sep="")
    if(!is.null(files)){
        if(args[["selectbpc"]]){
            cat("\n\tProcessing BPC(s) from XCMS files...\n")
            c <- getBPC2s(files = files, xset = xset, rt="raw", pdfname="BPCs_raw.pdf")
            cat("BPC(s) created...\n")
        }
        if(args[["selecttic"]]){
            cat("\n\tProcessing TIC(s) from XCMS files...\n")
            b <- getTIC2s(files = files, xset = xset, rt="raw", pdfname="TICs_raw.pdf")
            cat("TIC(s) created...\n")
        }
        if(args[["selecteic"]]){
            cat("\n\tProcessing EIC(s) from XCMS files...\n")
            cat(length(unknarg),"unknown(s) will be process !\n")
            plotUnknowns(resGC=resGC, unkn=unknarg, DB=DBarg, fileFrom="singlefile")
            cat("EIC(s) created...\n")
        }
    } else {
        #TODO add error message
        print("Error files is empty")
    }
}
if(!is.null(zipfile)) {
    files <- getMSFiles(directory)
    if(!is.null(files)) {
        if(args[["selectbpc"]]) {
            cat("\n\tProcessing BPC(s) from raw files...\n")
            c <- getBPC2s(files = files, rt="raw", pdfname="BPCs_raw.pdf")
            cat("BPC(s) created...\n")
        }
        if(args[["selecttic"]]) {
            cat("\n\tProcessing TIC(s) from raw files...\n")
            b <- getTIC2s(files = files, rt="raw", pdfname="TICs_raw.pdf")  
            cat("TIC(s) created...\n")
        }
        if(args[["selecteic"]]) {
            cat("\n\tProcessing EIC(s) from XCMS files...\n")
            cat(length(unknarg),"unknown(s) will be process !\n")
            plotUnknowns(resGC=resGC, unkn=unknarg, DB=DBarg, fileFrom="zipfile")
            cat("EIC(s) created...\n")
        }
    } else {
        #TODO add error message
        print("Error files is empty")
    } 
}

#test
system(paste('gs  -o TICsBPCs_merged.pdf  -sDEVICE=pdfwrite  -dPDFSETTINGS=/prepress  *Cs_raw.pdf'))
system(paste('gs  -o GCMS_EIC.pdf  -sDEVICE=pdfwrite  -dPDFSETTINGS=/prepress  Unknown_*'))

cat("\nEnd of '", modNamC, "' Galaxy module call: ", as.character(Sys.time()), "\n", sep = "")