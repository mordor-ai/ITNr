#' @title Adjust Matrix
#'
#' @description adjust the dimensions of a source object to the dimensions of a target object
#' @param source A matrix which should be adjusted (one-mode & directed).
#' @param target A matrix (one-mode & directed) to which the source object is compared with regard to its labels.
#' @param remove Should rows and columns that are not present in the target object be removed?
#' @param add Should rows and columns that are present in the target object but not in the source object be added to the source object?
#' @param value The value to be inserted if a new row or column is added. By default, new cells are filled with NA values, but other sensible values may include -Inf or 0.
#' @param returnlabels 	Return a list of added and removed row and column labels rather than the actual matrix, vector, or network object?
#' @export
#' @return Matrix


#
adjust_mat <- function(source, target, remove = TRUE, add = TRUE, value = NA,
                   returnlabels = FALSE) {

  # make sure the source is a list
  if (is.null(source)) {
    stop("The 'source' argument was not recognized.")
  } else if (class(source) == "matrix") {
    # wrap in list
    sources <- list()
    sources[[1]] <- source
    sources.initialtype <- "matrix"
  } else {
    stop(paste("Source data type not supported"))
  }

  # make sure the target is a list
  if (is.null(target)) {
    stop("The 'target' argument was not recognized.")
  } else if (class(target) == "matrix") {
    # wrap in list
    targets <- list()
    targets[[1]] <- target
    targets.initialtype <- "matrix"
  } else {
    stop(paste("Target data type not supported"))
  }

  # make sure that both lists (sources and targets) have the same length
  if (length(sources) == length(targets)) {
    # OK; do nothing
  } else if (length(sources) == 1) {
    for (i in 2:length(targets)) {
      sources[[i]] <- sources[[1]]
    }
  } else if (length(targets) == 1) {
    for (i in 2:length(sources)) {
      targets[[i]] <- targets[[1]]
    }
  } else {
    stop("Different numbers of sources and targets were provided.")
  }

  # convert each item if necessary and save nodal attributes
  sources.attribnames <- list()  # names of additional vertex attributes
  sources.attributes <- list()  # additional vertex attributes
  sources.types <- list()  # matrix, network etc.
  sources.onemode <- list()  # is the source network a one-mode network?
  sources.directed <- list()  # is the source network directed?
  sources.matrixnames <- list()  # names of additional matrices
  sources.matrices <- list()  # additional matrices stored in the source network
  targets.attribnames <- list()  # names of additional vertex attributes
  targets.attributes <- list()  # additional vertex attributes
  targets.types <- list()  # matrix, network etc.
  targets.onemode <- list()  # is the target network a one-mode network?
  targets.directed <- list()  # is the source network directed?
  for (i in 1:length(sources)) {
    sources.types[[i]] <- class(sources[[i]])
    if (class(sources[[i]]) == "matrix") {
      sources.onemode[[i]] <- TRUE#is.mat.onemode(sources[[i]])
      sources.directed[[i]] <- TRUE#is.mat.directed(sources[[i]])
    } else {
      sources[[i]] <- as.matrix(sources[[i]], ncol = 1)
    }

    targets.types[[i]] <- class(targets[[i]])
    if (class(targets[[i]]) == "matrix") {
      targets.onemode[[i]] <- TRUE#is.mat.onemode(targets[[i]])
      targets.directed[[i]] <- TRUE#is.mat.directed(targets[[i]])
    } else {
      targets[[i]] <- as.matrix(targets[[i]], ncol = 1)
    }
  }

  # impute row or column labels if only one of them is present
  for (i in 1:length(sources)) {
    if (is.null(rownames(sources[[i]])) && !is.null(colnames(sources[[i]])) &&
        nrow(sources[[i]]) == ncol(sources[[i]])) {
      rownames(sources[[i]]) <- colnames(sources[[i]])
    }
    if (is.null(colnames(sources[[i]])) && !is.null(rownames(sources[[i]])) &&
        nrow(sources[[i]]) == ncol(sources[[i]])) {
      colnames(sources[[i]]) <- rownames(sources[[i]])
    }
    if (is.null(rownames(targets[[i]])) && !is.null(colnames(targets[[i]])) &&
        nrow(targets[[i]]) == ncol(targets[[i]])) {
      rownames(targets[[i]]) <- colnames(targets[[i]])
    }
    if (is.null(colnames(targets[[i]])) && !is.null(rownames(targets[[i]])) &&
        nrow(targets[[i]]) == ncol(targets[[i]])) {
      colnames(targets[[i]]) <- rownames(targets[[i]])
    }
  }

  # throw error if there are duplicate names (first sources, then targets)
  for (i in 1:length(sources)) {
    if (class(sources[[i]]) %in% c("matrix", "data.frame")) {
      # row names
      if (!is.null(rownames(sources[[i]]))) {
        test.actual <- nrow(sources[[i]])
        test.unique <- length(unique(rownames(sources[[i]])))
        dif <- test.actual - test.unique
        if (dif > 1) {
          stop(paste0("At t = ", i, ", there are ", dif,
                      " duplicate source row names."))
        } else if (dif == 1) {
          stop(paste0("At t = ", i, ", there is ", dif,
                      " duplicate source row name."))
        }
      }
      # column names
      if (!is.null(colnames(sources[[i]]))) {
        test.actual <- ncol(sources[[i]])
        test.unique <- length(unique(colnames(sources[[i]])))
        dif <- test.actual - test.unique
        if (dif > 1) {
          stop(paste0("At t = ", i, ", there are ", dif,
                      " duplicate source column names."))
        } else if (dif == 1) {
          stop(paste0("At t = ", i, ", there is ", dif,
                      " duplicate source column name."))
        }
      }
    } else {
      # vector names
      if (!is.null(names(sources[[i]]))) {
        test.actual <- length(sources[[i]])
        test.unique <- length(unique(names(sources[[i]])))
        dif <- test.actual - test.unique
        if (dif > 1) {
          stop(paste0("At t = ", i, ", there are ", dif,
                      " duplicate source names."))
        } else if (dif == 1) {
          stop(paste0("At t = ", i, ", there is ", dif,
                      " duplicate source name."))
        }
      }
    }
  }
  for (i in 1:length(targets)) {
    if (class(targets[[i]]) %in% c("matrix", "data.frame")) {
      # row names
      if (!is.null(rownames(targets[[i]]))) {
        test.actual <- nrow(targets[[i]])
        test.unique <- length(unique(rownames(targets[[i]])))
        dif <- test.actual - test.unique
        if (dif > 1) {
          stop(paste0("At t = ", i, ", there are ", dif,
                      " duplicate target row names."))
        } else if (dif == 1) {
          stop(paste0("At t = ", i, ", there is ", dif,
                      " duplicate target row name."))
        }
      }
      # column names
      if (!is.null(colnames(targets[[i]]))) {
        test.actual <- ncol(targets[[i]])
        test.unique <- length(unique(colnames(targets[[i]])))
        dif <- test.actual - test.unique
        if (dif > 1) {
          stop(paste0("At t = ", i, ", there are ", dif,
                      " duplicate target column names."))
        } else if (dif == 1) {
          stop(paste0("At t = ", i, ", there is ", dif,
                      " duplicate target column name."))
        }
      }
    } else {
      # vector names
      if (!is.null(names(targets[[i]]))) {
        test.actual <- length(targets[[i]])
        test.unique <- length(unique(names(targets[[i]])))
        dif <- test.actual - test.unique
        if (dif > 1) {
          stop(paste0("At t = ", i, ", there are ", dif,
                      " duplicate target names."))
        } else if (dif == 1) {
          stop(paste0("At t = ", i, ", there is ", dif,
                      " duplicate target name."))
        }
      }
    }
  }

  # add original labels to saved network attributes (= matrices) if necessary
  for (i in 1:length(sources)) {
    if (sources.types[[i]] == "network" && !is.null(sources.matrices[[i]])
        && length(sources.matrices[[i]]) > 0) {
      for (j in 1:length(sources.matrices[[i]])) {
        if (nrow(as.matrix(sources.matrices[[i]][[j]])) !=
            nrow(as.matrix(sources[[i]])) ||
            ncol(as.matrix(sources.matrices[[i]][[j]])) !=
            ncol(as.matrix(sources[[i]]))) {
          warning(paste("Network attribute", sources.matrixnames[[i]][j],
                        "does not have the same dimensions as the source network at",
                        "time step", i, "."))
        }
        if (class(sources.matrices[[i]][[j]]) == "network") {
          if (sources.onemode[[i]] == TRUE) {
            sources.matrices[[i]][[j]] <- set.vertex.attribute(
              sources.matrices[[i]][[j]], "vertex.names",
              rownames(as.matrix(sources[[i]])))
          } else {
            sources.matrices[[i]][[j]] <- set.vertex.attribute(
              sources.matrices[[i]][[j]], "vertex.names",
              c(rownames(as.matrix(sources[[i]])),
                colnames(as.matrix(sources[[i]]))))
          }
        } else {
          rownames(sources.matrices[[i]][[j]]) <-
            rownames(as.matrix(sources[[i]]))
          colnames(sources.matrices[[i]][[j]]) <-
            colnames(as.matrix(sources[[i]]))
        }
      }
    }
  }

  # go through sources and targets and do the actual adjustment
  for (i in 1:length(sources)) {
    if (!is.vector(sources[[i]]) && !class(sources[[i]]) %in% c("matrix",
                                                                "network")) {
      stop(paste("Source item", i, "is not a matrix, network, or vector."))
    }
    if (!is.vector(targets[[i]]) && !class(targets[[i]]) %in% c("matrix",
                                                                "network")) {
      stop(paste("Target item", i, "is not a matrix, network, or vector."))
    }

    # add
    add.row.labels <- character()
    add.col.labels <- character()
    if (add == TRUE) {
      # compile source and target row and column labels
      nr <- nrow(sources[[i]])  # save for later use
      source.row.labels <- rownames(sources[[i]])
      if (!sources.types[[i]] %in% c("matrix", "network")) {
        source.col.labels <- rownames(sources[[i]])
      } else {
        source.col.labels <- colnames(sources[[i]])
      }
      if (sources.types[[i]] %in% c("matrix", "network")) {
        if (is.null(source.row.labels)) {
          stop(paste0("The source at t = ", i,
                      " does not contain any row labels."))
        }
        if (is.null(source.col.labels)) {
          stop(paste0("The source at t = ", i,
                      " does not contain any column labels."))
        }
      }

      target.row.labels <- rownames(targets[[i]])
      if (!targets.types[[i]] %in% c("matrix", "network")) {
        target.col.labels <- rownames(targets[[i]])
      } else {
        target.col.labels <- colnames(targets[[i]])
      }
      if (is.null(target.row.labels)) {
        stop(paste0("The target at t = ", i,
                    " does not contain any row labels."))
      }
      if (targets.types[[i]] %in% c("matrix", "network")) {
        if (is.null(target.col.labels)) {
          stop(paste0("The target at t = ", i,
                      " does not contain any column labels."))
        }
      }

      add.row.indices <- which(!target.row.labels %in% source.row.labels)
      add.row.labels <- target.row.labels[add.row.indices]
      add.col.indices <- which(!target.col.labels %in% source.col.labels)
      add.col.labels <- target.col.labels[add.col.indices]

      # adjust rows
      if (length(add.row.indices) > 0) {
        for (j in 1:length(add.row.indices)) {
          insert <- rep(value, ncol(sources[[i]]))
          part1 <- sources[[i]][0:(add.row.indices[j] - 1), ]
          if (class(part1) != "matrix") {
            if (sources.types[[i]] %in% c("matrix", "network")) {
              part1 <- matrix(part1, nrow = 1)
            } else {
              part1 <- matrix(part1, ncol = 1)
            }
          }
          rownames(part1) <- rownames(sources[[i]])[0:(add.row.indices[j] - 1)]
          if (add.row.indices[j] <= nrow(sources[[i]])) {
            part2 <- sources[[i]][add.row.indices[j]:nrow(sources[[i]]), ]
          } else {
            part2 <- matrix(ncol = ncol(sources[[i]]), nrow = 0)
          }
          if (class(part2) != "matrix") {
            part2 <- matrix(part2, nrow = 1)
          }
          if (nrow(part2) > 0) {
            rownames(part2) <- rownames(sources[[i]])[add.row.indices[j]:
                                                        nrow(sources[[i]])]
            sources[[i]] <- rbind(part1, insert, part2)
          } else {
            sources[[i]] <- rbind(part1, insert)
          }
          rownames(sources[[i]])[add.row.indices[j]] <- add.row.labels[j]

          # adjust nodal attributes (in the one-mode case)
        }
      }

      # adjust columns
      if (length(add.col.indices) > 0 && sources.types[[i]] %in% c("matrix",
                                                                   "network")) {
        for (j in 1:length(add.col.indices)) {
          insert <- rep(value, nrow(sources[[i]]))
          part1 <- sources[[i]][, 0:(add.col.indices[j] - 1)]
          if (class(part1) != "matrix") {
            part1 <- matrix(part1, ncol = 1)
          }
          colnames(part1) <- colnames(sources[[i]])[0:(add.col.indices[j] - 1)]
          if (add.col.indices[j] <= ncol(sources[[i]])) {
            part2 <- sources[[i]][, add.col.indices[j]:ncol(sources[[i]])]
          } else {  # if last column, add empty column as second part
            part2 <- matrix(nrow = nrow(sources[[i]]), ncol = 0)
          }
          if (class(part2) != "matrix") {
            part2 <- matrix(part2, ncol = 1)
          }
          if (ncol(part2) > 0) {
            colnames(part2) <- colnames(sources[[i]])[add.col.indices[j]:
                                                        ncol(sources[[i]])]
            sources[[i]] <- cbind(part1, insert, part2)
          } else {
            sources[[i]] <- cbind(part1, insert)
          }
          colnames(sources[[i]])[add.col.indices[j]] <- add.col.labels[j]
        }
      }

      # adjust nodal attributes for two-mode networks

    }

    removed.rows <- character()
    removed.columns <- character()
    if (remove == TRUE) {
      # compile source and target row and column labels
      nr <- nrow(sources[[i]])  # save for later use
      source.row.labels <- rownames(sources[[i]])
      if (!sources.types[[i]] %in% c("matrix", "network")) {
        source.col.labels <- rownames(sources[[i]])
      } else {
        source.col.labels <- colnames(sources[[i]])
      }
      if (sources.types[[i]] %in% c("matrix", "network")) {
        if (nr == 0) {
          stop(paste0("The source at t = ", i, " has no rows."))
        }
        if (is.null(source.row.labels)) {
          stop(paste0("The source at t = ", i,
                      " does not contain any row labels."))
        }
        if (is.null(source.col.labels)) {
          stop(paste0("The source at t = ", i,
                      " does not contain any column labels."))
        }
      }

      target.row.labels <- rownames(targets[[i]])
      if (!targets.types[[i]] %in% c("matrix", "network")) {
        target.col.labels <- rownames(targets[[i]])
      } else {
        target.col.labels <- colnames(targets[[i]])
      }
      if (targets.types[[i]] %in% c("matrix", "network")) {
        if (is.null(target.row.labels)) {
          stop(paste0("The target at t = ", i,
                      " does not contain any row labels."))
        }
        if (is.null(target.col.labels)) {
          stop(paste0("The target at t = ", i,
                      " does not contain any column labels."))
        }
      }

      # remove
      source.row.labels <- rownames(sources[[i]])
      source.col.labels <- colnames(sources[[i]])
      target.row.labels <- rownames(targets[[i]])
      target.col.labels <- colnames(targets[[i]])
      keep.row.indices <- which(source.row.labels %in% target.row.labels)
      if (sources.types[[i]] %in% c("matrix", "network") &&
          targets.types[[i]] %in% c("matrix", "network")) {
        keep.col.indices <- which(source.col.labels %in% target.col.labels)
      } else if (sources.types[[i]] %in% c("matrix", "network")
                 && !targets.types[[i]] %in% c("matrix", "network")) {
        # target is a vector -> keep all columns of source if not onemode
        if (sources.onemode[[i]] == TRUE) {  # columns same as rows
          keep.col.indices <- keep.row.indices
        } else {
          keep.col.indices <- 1:ncol(sources[[i]])
        }
      } else {
        keep.col.indices <- 1
      }
      removed.rows <- which(!1:nrow(as.matrix(sources[[i]])) %in%
                              keep.row.indices)
      removed.columns <- which(!1:ncol(as.matrix(sources[[i]])) %in%
                                 keep.col.indices)

      sources[[i]] <- as.matrix(sources[[i]][keep.row.indices,
                                             keep.col.indices])

    }

    # sort source (and attributes) according to row and column names of target
    #    if (length(sources.attributes[[i]]) > 0) {
    #      for (j in 1:length(sources.attributes[[i]])) {
    #        if (!is.null(sources.attributes[[i]][[j]]) &&
    #            length(sources.attributes[[i]][[j]]) > 0) {
    #          if (sources.onemode[[i]] == TRUE) {
    #            names(sources.attributes[[i]][[j]]) <- rownames(sources[[i]])
    #            sources.attributes[[i]][[j]] <-
    #                sources.attributes[[i]][[j]][rownames(sources[[i]])]
    #          } else {
    #            names(sources.attributes[[i]][[j]]) <- c(rownames(sources[[i]]),
    #                rownames(sources[[i]]))
    #            sources.attributes[[i]][[j]] <-
    #                c(sources.attributes[[i]][[j]][rownames(sources[[i]])],
    #                sources.attributes[[i]][[j]][colnames(sources[[i]])])
    #          }
    #        }
    #      }
    #    }
    #
    if (sources.types[[i]] %in% c("matrix", "network") &&
        targets.types[[i]] %in% c("matrix", "network") &&
        nrow(sources[[i]]) == nrow(targets[[i]]) &&
        ncol(sources[[i]]) == ncol(targets[[i]])) {
      sources[[i]] <- sources[[i]][rownames(targets[[i]]),
                                   colnames(targets[[i]])]
    } else if (sources.types[[i]] %in% c("matrix", "network") &&
               !targets.types[[i]] %in% c("matrix", "network") &&
               nrow(sources[[i]]) == nrow(targets[[i]])) {
      sources[[i]] <- sources[[i]][rownames(targets[[i]]),
                                   rownames(targets[[i]])]
    } else if (length(sources[[i]]) == nrow(targets[[i]])) {
      # source is a vector, irrespective of the target
      sources[[i]] <- sources[[i]][rownames(targets[[i]]), ]
    } else if (add == FALSE && (nrow(sources[[i]]) < nrow(targets[[i]]) ||
                                any(rownames(sources[[i]]) != rownames(targets[[i]])))) {
    }

    # convert back into network

    # convert vectors back from one-column matrices to vectors
    if (!sources.types[[i]] %in% c("matrix", "network") &&
        class(sources[[i]]) == "matrix" && ncol(sources[[i]]) == 1) {
      sources[[i]] <- sources[[i]][, 1]
    }

    # return added and removed labels instead of actual objects
    if (returnlabels == TRUE) {
      sources[[i]] <- list()
      sources[[i]]$removed.row <- removed.rows
      sources[[i]]$removed.col <- removed.columns
      sources[[i]]$added.row <- add.row.labels
      sources[[i]]$added.col <- add.col.labels
    }
  }

  # adjust network attributes (= matrices) recursively and add back in


  if (sources.initialtype == "list") {
    return(sources)
  } else {
    return(sources[[1]])
  }
}
