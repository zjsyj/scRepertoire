#' Calculate rarefaction based on the abundance of clones
#' 
#' This functions uses the Hill numbers of order q: species richness (**q = 0**), 
#' Shannon diversity (**q = 1**), the exponential of Shannon entropy and Simpson 
#' diversity (**q = 2**, the inverse of Simpson concentration) to compute diversity 
#' estimates for rarefaction and extrapolation. The function relies on the
#' [iNEXT::iNEXT()] R package. Please read and cite the 
#' [manuscript](https://besjournals.onlinelibrary.wiley.com/doi/10.1111/2041-210X.12613) 
#' if using this function. The input into the iNEXT calculation is abundance, 
#' incidence-based calculations are not supported.
#' 
#' @examples
#' #Making combined contig data
#' combined <- combineTCR(contig_list, 
#'                         samples = c("P17B", "P17L", "P18B", "P18L", 
#'                                     "P19B","P19L", "P20B", "P20L"))
#' clonalRarefaction(combined[c(1,2)], cloneCall = "gene", n.boots = 3)
#'
#'
#' @param input.data The product of [combineTCR()], 
#' [combineBCR()], or [combineExpression()].
#' @param cloneCall How to call the clone - VDJC gene (**gene**), 
#' CDR3 nucleotide (**nt**), CDR3 amino acid (**aa**),
#' VDJC gene + CDR3 nucleotide (**strict**) or a custom variable 
#' in the data. 
#' @param chain indicate if both or a specific chain should be used - 
#' e.g. "both", "TRA", "TRG", "IGH", "IGL".
#' @param group.by The variable to use for grouping.
#' @param plot.type sample-size-based rarefaction/extrapolation curve 
#' (`type = 1`); sample completeness curve (`type = 2`); 
#' coverage-based rarefaction/extrapolation curve (`type = 3`).   
#' @param hill.numbers The Hill numbers to be plotted out 
#' (0 - species richness, 1 - Shannon, 2 - Simpson)
#' @param n.boots The number of bootstraps to downsample in order 
#' to get mean diversity.
#' @param exportTable Exports a table of the data into the global 
#' environment in addition to the visualization.
#' @param palette Colors to use in visualization - input any 
#' [hcl.pals][grDevices::hcl.pals].
#'
#' @importFrom iNEXT iNEXT ggiNEXT
#' @export
#' @concept Visualizing_Clones
clonalRarefaction <- function(input.data,
                              cloneCall = "strict", 
                              chain = "both", 
                              group.by = NULL, 
                              plot.type = 1,
                              hill.numbers = 0,
                              n.boots = 20,
                              exportTable = FALSE,
                              palette = "inferno") {
  input.data <- .data.wrangle(input.data, 
                              group.by, 
                              .theCall(input.data, cloneCall, check.df = FALSE), 
                              chain)
  cloneCall <- .theCall(input.data, cloneCall)
  sco <- is_seurat_object(input.data) | is_se_object(input.data)

  if(!is.null(group.by) & !sco) {
    input.data <- .groupList(input.data, group.by)
  }
  
  mat.list <- lapply(input.data, function(x) {
                  table(x[,cloneCall])
  })
  col <- length(input.data)
  mat <- iNEXT(mat.list, q=hill.numbers, datatype="abundance",nboot = n.boots) 
  plot <- suppressMessages(ggiNEXT(mat, type=plot.type) + 
            scale_shape_manual(values = rep(16,col)) + 
            scale_fill_manual(values = c(.colorizer(palette,col))) + 
            scale_color_manual(values = c(.colorizer(palette,col)))  + 
            theme_classic())
  if (exportTable == TRUE) { 
    return(plot["data"]) 
  } else {
    return(plot)
  }
  
}
