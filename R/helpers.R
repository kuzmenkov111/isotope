#' @export
getAvailableLayoutModes <- function(){
  availableLayoutModes <- c('masonry','fitRows','cellsByRow','vertical','packery',
                            'masonryHorizontal','fitColumns','cellsByColumn','horizontal')
  availableLayoutModes <- c('masonry','fitRows','vertical','packery')
  availableLayoutModes
}

#
# #' @export
# getFilterClasses <- function(d, filterCols = NULL){
#
#   nms <- filterCols
#   l <- lapply(nms,function(n){
#     tpl <- '<p class="{n}"></p>'
#     n <- gsub("[[:punct:] ]","-",n)
#     pystr_format(tpl,n=n)
#     x <- whisker.render(tpl,list(n=n))
#     x <- gsub("__|","{{",x,fixed=TRUE)
#     x <- gsub("|__","}}",x,fixed=TRUE)
#     x
#   })
#   paste('<div class="defaultBoxOut"><div class="defaultBoxIn">',
#         paste(unlist(l), collapse="\n"),
#         '</div></div>')
# }
#


#' @export
getStdTpl <- function(d, filterCols = NULL, sortCols = NULL){

  if(is.null(filterCols) && is.null(sortCols)){
    nms <- names(d)
  } else{
    nms <- union(filterCols,sortCols)
  }
  nms <- nms[!is.na(nms)]
  #nms <- filterCols
  l <- lapply(nms,function(n){
    if(n == "imageUrl")
      tpl <-  '<img class="{n1}" src="__|{{n2}}|__" width="20px"/>'
    else
      tpl <- '<p class="{{n}}"><strong>{{n}}: </strong>__|{{n}}|__</p>'
    x <- whisker.render(tpl,list(n=n))
    x <- gsub("__|","{{",x,fixed=TRUE)
    x <- gsub("|__","}}",x,fixed=TRUE)
    x
  })
  paste('<div class="defaultBoxOut"><div class="defaultBoxIn">',
        paste(unlist(l), collapse="\n"),
        '</div></div>')
}


#' @export
#'
htmlItems <- function(d, filterCols, elemTpl = NULL, ncols = 4){

  elemTplStd <- getStdTpl(d)
  elemTpl <- elemTpl %||% elemTplStd


  ## TODO
  #Apply Filter classes
  #filterCols <- c('tags','status','author')

  #names(d) <- gsub(" ","-",names(d),fixed= TRUE)

  lFilters <- lapply(filterCols,function(col){
    catFilters <-lapply(d[,col],function(x){
      x <- as.character(nullToEmpty(x, empty="empty"))
      #filterRowValues <- c(col,strsplit(x,",")[[1]]) ## OJO para los tags separados con ,
      filterRowValues <- gsub("[[:punct:] ]","-",x)
      elemClass <- paste(filterRowValues,collapse = "-")
      col <- gsub(" ","-",col,fixed= TRUE)
      paste(col,elemClass,sep='-')
    })
    catFilters
  })
  dtmp <- as.data.frame(mapply(c,lFilters))
  elem <- unite_(dtmp,"classes",names(dtmp),sep=" ")
  elemClass <- paste("element-item",elem$classes)
  #tpl <- paste0('<div class="{{itemClasses}}" style="width:', round(100/ncols),'%" >',elemTpl,'\n</div>')
  tpl <- paste0('<div class="{{itemClasses}}" >',elemTpl,'\n</div>')
  d$itemClasses <- elemClass
  whisker.render.df(tpl,d)
}

#' @export
#'
filterBtnHtml <- function(d, filterCols = NULL){
  #filterCols <- c('tags','status','author')
  filterCols <- filterCols %||% names(d)
  buttons <- lapply(filterCols, function(col){
    l <- lapply(d[,col],function(x){
      x <- nullToEmpty(x, empty="empty")
      #filterRowValues <- paste(col,strsplit(x,",")[[1]],sep"-")
      #filterRowValues <- c(strsplit(x,",")[[1]]) ### OJOOOO cuando están separados con ,
      filterRowValues <- x
      paste0(".",c(col,filterRowValues),collapse = "")
    })
    l
  })
  #   names(buttons) <- filterCols
  #
  #   Map(function(b1){
  #
  #   },buttons)

  buttons <- unique(unlist(buttons))

  btnsHtml <- lapply(buttons,function(b){
    tags$button(b,class="button",`data-filter`= b)
  })
  btnsHtml <- Filter(function(b){!grepl("empty",b)},btnsHtml)
  filterDiv <- tags$div(id="filters",class="button-group",
                        #tags$button('All',class="is-checked",`data-filter`="*"),
                        tags$button('All',class="button",`data-filter`="*"),
                        btnsHtml
  )
  doRenderTags(filterDiv)
}

#' @export
sortBtnHtml <- function(d,sortCols = NULL, sortTitle = 'Sort'){
  sortCols <- sortCols %||% names(d)
  buttons <- sortCols
  #<button class="button" data-sort-by="name">name</button>

  if(is.null(names(buttons))) names(buttons) <- buttons

  btnsHtml <- lapply(seq_along(buttons),function(b,bnames,i){
    tags$button(bnames[[i]],class="button mb1",`data-sort-by`= b[[i]])
  }, b=buttons, bnames=names(buttons))
  sortDiv <- tags$div(id="sorts",class="button-group",
                      tags$h3(sortTitle),
                      tags$button("Original Order",
                                  class="button mb1",`data-sort-by`= "original-order"),
                      btnsHtml
  )
  doRenderTags(sortDiv)
}


#' @export
selectizeOpts <- function(d, filterCols){
  #filterCols <- c('tags','status','author')
  df <- d[c(filterCols)]
  l <- lapply(filterCols,function(col){
    df <- d[col]
    df$groupId <- col
    names(df) <- c("filterValueId","groupId")
    df <- df[!is.null(df$filterValueId),]
    df
  })
  optsDf <- do.call(rbind.data.frame, l)
  optsDf <- optsDf[optsDf$filterValueId != "",]
  optsDf <- optsDf[!duplicated(optsDf),]
  optsDf$filterValueId <- as.character(optsDf$filterValueId)
  optsDf <- ddply(optsDf, names(optsDf),function(d){
    #x <- strsplit(d$filterValueId,",")[[1]] ## OJO when sep ,
    x <- gsub("[[:punct:]]","",d$filterValueId)
    df <- data.frame(filterValueId = x, stringsAsFactors = FALSE)
    df$groupId <- d$groupId
    df
  })
  optsDf <- optsDf[!duplicated(optsDf),]
  optsDf <- optsDf[with(optsDf,order(groupId,filterValueId)),]
  optsDf$filterValueLabel <- optsDf$filterValueId
  optsDf$filterValueId <- gsub(" ","-",optsDf$filterValueId ,fixed= TRUE)
  group <- gsub(" ","-",optsDf$groupId,fixed= TRUE)
  optsDf$filterValueId <- paste(group,optsDf$filterValueId,sep="-")
  optsDf
}



