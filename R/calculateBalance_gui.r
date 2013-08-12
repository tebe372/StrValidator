################################################################################
# TODO LIST
# TODO: Pass option ignoreCase to subset (and implement in subset)

################################################################################
# CHANGE LOG
# 26.07.2013: Removed parameters 'minHeight', 'maxHeight', 'matchSource' and related code.
# 26.07.2013: Changed parameter 'fixed' to 'word' for 'checkSubset' function.
# 18.07.2013: Check before overwrite object (new function).
# 17.07.2013: Added check subsetting.
# 11.07.2013: Added save GUI settings.
# 10.07.2013: Check if object exist and ask for overwrite or new name if it does.
# 11.06.2013: Added 'inherits=FALSE' to 'exists'.
# 04.06.2013: Fixed bug in 'missingCol'.
# 29.05.2013: Added subset check.
# 24.05.2013: Improved error message for missing columns.
# 24.05.2013: Fixed save with correct name.
# 17.05.2013: listDataFrames() -> listObjects()
# 09.05.2013: .result removed, added save as group.
# 18.04.2013: Added reference drop down and ref in call to calculateBalance.
# 14.04.2013: First version.

#' @title Calculate Balance
#'
#' @description
#' \code{calculateBalance_gui} is a GUI wrapper for the \code{calculateBalance}
#'  function.
#'
#' @details
#' Simplifies the use of the \code{calculateBalance} function by providing 
#' a graphical user interface.
#' 
#' @param env environment in wich to search for data frames and save result.
#' @param savegui logical indicating if GUI settings should be saved in the environment.
#' @param debug logical indicating printing debug information.
#' 
#' @return data.frame in slim format.
#' 

calculateBalance_gui <- function(env=parent.frame(), savegui=NULL,
                                 debug=FALSE){
  
  # Load dependencies.  
  require("gWidgets")
  options(guiToolkit="RGtk2")

  # Global variables.
  .gData <- NULL
  .gRef <- NULL
  
  if(debug){
    print(paste("IN:", match.call()[[1]]))
  }
  
  # WINDOW ####################################################################
  
  if(debug){
    print("WINDOW")
  }  

  # Main window.
  w <- gwindow(title="Calculate balance", visible=FALSE)

  # Handler for saving GUI state.
  addHandlerDestroy(w, handler = function (h, ...) {
    .saveSettings()
  })
  
  gv <- ggroup(horizontal=FALSE,
               spacing=8,
               use.scrollwindow=FALSE,
               container = w,
               expand=TRUE) 
  
  # FRAME 0 ###################################################################
  
  if(debug){
    print("FRAME 0")
  }  
  
  f0 <- gframe(text = "Datasets",
               horizontal=TRUE,
               spacing = 5,
               container = gv) 
  
  g0 <- glayout(container = f0, spacing = 1)

  # Dataset -------------------------------------------------------------------
  
  g0[1,1] <- glabel(text="Select dataset:", container=g0)
  
  dfs <- c("<Select a dataset>", listObjects(env=env, objClass="data.frame"))
  
  g0[1,2] <- g0_data_drp <- gdroplist(items=dfs, 
                           selected = 1,
                           editable = FALSE,
                           container = g0)
  g0[1,3] <- g0_data_samples_lbl <- glabel(text="", container=g0)
  
  addHandlerChanged(g0_data_drp, handler = function (h, ...) {
    
    val_obj <- svalue(g0_data_drp)
    
    if(exists(val_obj, envir=env, inherits = FALSE)){
      
      .gData <<- get(val_obj, envir=env)
      
      # Check if required columns...
      requiredCol <- c("Sample.Name", "Marker", "Dye", "Height")
      slimmed <- sum(grepl("Height",names(.gData), fixed=TRUE)) == 1
      
      if(!all(requiredCol %in% colnames(.gData))){
        
        missingCol <- requiredCol[!requiredCol %in% colnames(.gData)]

        message <- paste("Additional columns required:\n",
                         paste(missingCol, collapse="\n"), sep="")
        
        gmessage(message, title="message",
                 icon = "error",
                 parent = w) 
      
        # Reset components.
        .gData <<- NULL
        svalue(g0_data_drp, index=TRUE) <- 1
        svalue(g0_data_samples_lbl) <- ""
        svalue(f4_save_edt) <- ""
        
      } else if (!slimmed) {
  
        message <- paste("The dataset is too fat!\n\n",
                         "There can only be 1 'Height' column\n",
                         "Slim the dataset in the 'EDIT' tab", sep="")
        
        gmessage(message, title="message",
                 icon = "error",
                 parent = w) 
        
        # Reset components.
        .gData <<- NULL
        svalue(g0_data_drp, index=TRUE) <- 1
        svalue(g0_data_samples_lbl) <- ""
        svalue(f4_save_edt) <- ""
        
      }else {

        # Load or change components.

        svalue(g0_data_samples_lbl) <- paste(length(unique(.gData$Sample.Name)),
                                          "samples.")
        svalue(f4_save_edt) <- paste(val_obj, "_balance", sep="")
        
      }
      
    } else {
      
      # Reset components.
      svalue(g0_data_samples_lbl) <- ""
      .gData <<- NULL
      svalue(f4_save_edt) <- ""
      
    }    
  } )  

  # Reference -----------------------------------------------------------------
  
  g0[2,1] <- glabel(text="Select reference dataset:", container=g0)

  # NB! dfs defined in previous section.
  g0[2,2] <- g0_ref_drp <- gdroplist(items=dfs, 
                                   selected = 1,
                                   editable = FALSE,
                                   container = g0)
  g0[2,3] <- g0_ref_samples_lbl <- glabel(text="", container=g0)
  
  addHandlerChanged(g0_ref_drp, handler = function (h, ...) {
    
    val_obj <- svalue(g0_ref_drp)
    
    if(exists(val_obj, envir=env, inherits = FALSE)){
      
      .gRef <<- get(val_obj, envir=env)
      
      # Check if required columns...
      requiredCol <- c("Sample.Name", "Marker", "Allele")
      slimmed <- sum(grepl("Allele",names(.gRef), fixed=TRUE)) == 1
      
      if(!all(requiredCol %in% colnames(.gRef))){
        
        missingCol <- requiredCol[!requiredCol %in% colnames(.gRef)]

        message <- paste("Additional columns required:\n",
                         paste(missingCol, collapse="\n"), sep="")
        
        gmessage(message, title="message",
                 icon = "error",
                 parent = w) 
      
        # Reset components.
        .gRef <<- NULL
        svalue(g0_ref_drp, index=TRUE) <- 1
        svalue(g0_ref_samples_lbl) <- ""
        
      } else if (!slimmed) {
        
        message <- paste("The dataset is too fat!\n\n",
                         "There can only be 1 'Allele' column\n",
                         "Slim the dataset in the 'EDIT' tab", sep="")
        
        gmessage(message, title="message",
                 icon = "error",
                 parent = w) 
        
        # Reset components.
        .gRef <<- NULL
        svalue(g0_ref_drp, index=TRUE) <- 1
        svalue(g0_ref_samples_lbl) <- ""
        
      }else {
        
        # Load or change components.
        svalue(g0_ref_samples_lbl) <- paste(length(unique(.gRef$Sample.Name)),
                                          "samples.")
        
      }
      
    } else {
      
      # Reset components.
      svalue(g0_ref_samples_lbl) <- ""
      .gRef <<- NULL
      
    }    
  } )  
  
  # CHECK ---------------------------------------------------------------------
  
  if(debug){
    print("CHECK")
  }  
  
  g0[3,2] <- g0_check_btn <- gbutton(text="Check subsetting",
                                  border=TRUE,
                                  container=g0)
  
  addHandlerChanged(g0_check_btn, handler = function(h, ...) {
    
    # Get values.
    val_data <- .gData
    val_ref <- .gRef
    val_ignore <- svalue(f1_ignore_chk)
    val_word <- FALSE
    
    if (!is.null(.gData) || !is.null(.gRef)){
      
      chksubset_w <- gwindow(title = "Check subsetting",
                             visible = FALSE, name=title,
                             width = NULL, height= NULL, parent=w,
                             handler = NULL, action = NULL)
      
      chksubset_txt <- checkSubset(data=val_data,
                                   ref=val_ref,
                                   console=FALSE,
                                   ignoreCase=val_ignore,
                                   word=val_word)
      
      gtext (text = chksubset_txt, width = NULL, height = 300, font.attr = NULL, 
             wrap = FALSE, container = chksubset_w)
      
      visible(chksubset_w) <- TRUE
      
    } else {
      
      gmessage(message="Data frame is NULL!\n\n
               Make sure to select a dataset and a reference set",
               title="Error",
               icon = "error")      
      
    } 
    
  } )
  
  # FRAME 1 ###################################################################
  
  if(debug){
    print("FRAME 1")
  }  
  
  f1 <- gframe(text = "Options",
               horizontal=FALSE,
               spacing = 10,
               container = gv) 

  f1_savegui_chk <- gcheckbox(text="Save GUI settings",
                              checked=FALSE,
                              container=f1)
  
  f1_ignore_chk <- gcheckbox(text="Ignore case",
                         checked=TRUE,
                         container=f1)

  f1_options1 <- c("Calculate balance for each sample",
                "Calculate average balance across all samples")
  
  f1_perSample_opt <- gradio(items=f1_options1,
                             selected=1,
                             horizontal=FALSE,
                             container=f1)
  
  f1_options2 <- c("Calculate locus balance proportional to the whole sample",
                "Normalise locus balance to the locus with the highest total peak height")
  
  f1_lb_opt <- gradio(items=f1_options2,
                      selected=1,
                      horizontal=FALSE,
                      container=f1)

  f1_options3 <- c("Calculate locus balance within each dye",
                "Calculate locus balance global across all dyes")
  
  f1_perDye_opt <- gradio(items=f1_options3,
                          selected=1,
                          horizontal=FALSE,
                          container=f1)

  # FRAME 4 ###################################################################
  
  if(debug){
    print("FRAME 4")
  }  

  f4 <- gframe(text = "Save as",
               horizontal=TRUE,
               spacing = 5,
               container = gv) 
  
  glabel(text="Name for result:", container=f4)
  
  f4_save_edt <- gedit(text="", container=f4)

  # BUTTON ####################################################################

  if(debug){
    print("BUTTON")
  }  
  
  calculate_btn <- gbutton(text="Calculate",
                      border=TRUE,
                      container=gv)
  
  addHandlerChanged(calculate_btn, handler = function(h, ...) {
    
    # Get values.
    val_perSample <- svalue(f1_perSample_opt, index=TRUE) == 1
    val_lb <- svalue(f1_lb_opt, index=TRUE)
    val_perDye <- svalue(f1_perDye_opt, index=TRUE) == 1
    val_ignore <- svalue(f1_ignore_chk)
    val_data <- .gData
    val_ref <- .gRef
    val_name <- svalue(f4_save_edt)
    
    if(debug){
      print("Read Values:")
      print("val_perSample")
      print(val_perSample)
      print("val_lb")
      print(val_lb)
      print("val_perDye")
      print(val_perDye)
      print("val_ignore")
      print(val_ignore)
      print("val_name")
      print(val_name)
      print("val_data")
      print(head(val_data))
      print("val_ref")
      print((val_ref))
    }
    
    if(!is.null(.gData) & !is.null(.gRef)){
      
      if(val_lb == 1){
        val_lb <- "prop"
      } else {
        val_lb <- "norm"
      }

      if(debug){
        print("Sent Values:")
        print("val_perSample")
        print(val_perSample)
        print("val_lb")
        print(val_lb)
        print("val_perDye")
        print(val_perDye)
        print("val_ignore")
        print(val_ignore)
      }
  
      # Change button.
      svalue(calculate_btn) <- "Processing..."
      enabled(calculate_btn) <- FALSE
      
      datanew <- calculateBalance(data=val_data,
                                  ref=val_ref,
                                  perSample=val_perSample,
                                  lb=val_lb,
                                  perDye=val_perDye,
                                  ignoreCase=val_ignore)
      
      # Save data.
      saveObject(name=val_name, object=datanew, parent=w, env=env)
      
      if(debug){
        print(datanew)
        print(paste("EXIT:", match.call()[[1]]))
      }
      
      # Close GUI.
      dispose(w)
      
    } else {

      message <- "A dataset and a reference dataset have to be selected."
      
      gmessage(message, title="Datasets not selected",
               icon = "error",
               parent = w) 
      
    }
    
  } )

  # INTERNAL FUNCTIONS ########################################################
  
  .loadSavedSettings <- function(){
    
    # First check status of save flag.
    if(!is.null(savegui)){
      svalue(f1_savegui_chk) <- savegui
      enabled(f1_savegui_chk) <- FALSE
      if(debug){
        print("Save GUI status set!")
      }  
    } else {
      # Load save flag.
      if(exists(".calculateBalance_gui_savegui", envir=env, inherits = FALSE)){
        svalue(f1_savegui_chk) <- get(".calculateBalance_gui_savegui", envir=env)
      }
      if(debug){
        print("Save GUI status loaded!")
      }  
    }
    if(debug){
      print(svalue(f1_savegui_chk))
    }  
    
    # Then load settings if true.
    if(svalue(f1_savegui_chk)){
      if(exists(".calculateBalance_gui_perSample", envir=env, inherits = FALSE)){
        svalue(f1_perSample_opt) <- get(".calculateBalance_gui_perSample", envir=env)
      }
      if(exists(".calculateBalance_gui_lb", envir=env, inherits = FALSE)){
        svalue(f1_lb_opt) <- get(".calculateBalance_gui_lb", envir=env)
      }
      if(exists(".calculateBalance_gui_perDye", envir=env, inherits = FALSE)){
        svalue(f1_perDye_opt) <- get(".calculateBalance_gui_perDye", envir=env)
      }
      if(exists(".calculateBalance_gui_ignore", envir=env, inherits = FALSE)){
        svalue(f1_ignore_chk) <- get(".calculateBalance_gui_ignore", envir=env)
      }
      if(debug){
        print("Saved settings loaded!")
      }
    }
    
  }
  
  .saveSettings <- function(){
    
    # Then save settings if true.
    if(svalue(f1_savegui_chk)){
      
      assign(x=".calculateBalance_gui_savegui", value=svalue(f1_savegui_chk), envir=env)
      assign(x=".calculateBalance_gui_perSample", value=svalue(f1_perSample_opt), envir=env)
      assign(x=".calculateBalance_gui_lb", value=svalue(f1_lb_opt), envir=env)
      assign(x=".calculateBalance_gui_perDye", value=svalue(f1_perDye_opt), envir=env)
      assign(x=".calculateBalance_gui_ignore", value=svalue(f1_ignore_chk), envir=env)
      
    } else { # or remove all saved values if false.
      
      if(exists(".calculateBalance_gui_savegui", envir=env, inherits = FALSE)){
        remove(".calculateBalance_gui_savegui", envir = env)
      }
      if(exists(".calculateBalance_gui_perSample", envir=env, inherits = FALSE)){
        remove(".calculateBalance_gui_perSample", envir = env)
      }
      if(exists(".calculateBalance_gui_lb", envir=env, inherits = FALSE)){
        remove(".calculateBalance_gui_lb", envir = env)
      }
      if(exists(".calculateBalance_gui_perDye", envir=env, inherits = FALSE)){
        remove(".calculateBalance_gui_perDye", envir = env)
      }
      if(exists(".calculateBalance_gui_ignore", envir=env, inherits = FALSE)){
        remove(".calculateBalance_gui_ignore", envir = env)
      }
      
      if(debug){
        print("Settings cleared!")
      }
    }
    
    if(debug){
      print("Settings saved!")
    }
    
  }
  
  # END GUI ###################################################################
  
  # Load GUI settings.
  .loadSavedSettings()
  
  # Show GUI.
  visible(w) <- TRUE
  
}
