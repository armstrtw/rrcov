## Test the exact fit property of CovMcd
doexact <- function(){
    exact <-function(seed=1234){
    	
	set.seed(seed)

	n1 <- 45
        p <- 2
        x1 <- matrix(rnorm(p*n1),nrow=n1, ncol=p)
        x1[,p] <- x1[,p] + 3
        n2 <- 55
        m1 <- 0
        m2 <- 3
        x2 <- cbind(rnorm(n2),rep(m2,n2))
        x<-rbind(x1,x2)
        colnames(x) <- c("X1","X2")
        x
    }
    print(CovMcd(exact()))
}

dodata <- function(nrep=1, time=FALSE, short=FALSE, full=TRUE, method = c("FASTMCD","MASS")){
##@bdescr
## Test the function covMcd() on the literature datasets:
##
## Call covMcd() for all regression datasets available in rrcov and print:
##  - execution time (if time == TRUE)
##  - objective fucntion
##  - best subsample found (if short == false)
##  - outliers identified (with cutoff 0.975) (if short == false)
##  - estimated center and covarinance matrix if full == TRUE)
##
##@edescr
##
##@in  nrep              : [integer] number of repetitions to use for estimating the
##                                   (average) execution time
##@in  time              : [boolean] whether to evaluate the execution time
##@in  short             : [boolean] whether to do short output (i.e. only the
##                                   objective function value). If short == FALSE,
##                                   the best subsample and the identified outliers are
##                                   printed. See also the parameter full below
##@in  full              : [boolean] whether to print the estimated cente and covariance matrix
##@in  method            : [character] select a method: one of (FASTMCD, MASS)

    domcd <- function(x, xname, nrep=1){
        n <- dim(x)[1]
        p <- dim(x)[2]
        if(method == "MASS"){
            mcd<-cov.mcd(x)
            quan <- as.integer(floor((n + p + 1)/2))   #default: floor((n+p+1)/2)
        }
        else{
            mcd<-CovMcd(x, trace=FALSE)
            quan <- as.integer(mcd@quan)
        }

        if(method == "MASS")
            crit <- mcd@crit
        else
            crit <- log(mcd@crit)

        if(time){
           xtime <- system.time(dorep(x, nrep, method))[1]/nrep
           xres <- sprintf("%3d %3d %3d %12.6f %10.3f\n", dim(x)[1], dim(x)[2], quan, crit, xtime)
        }
        else{
            xres <- sprintf("%3d %3d %3d %12.6f\n", dim(x)[1], dim(x)[2], quan, crit)
        }
        lpad<-lname-nchar(xname)
        cat(pad.right(xname,lpad), xres)

        if(!short){
            cat("Best subsample: \n")
            print(mcd@best)

            ibad <- which(mcd@wt==0)
            names(ibad) <- NULL
            nbad <- length(ibad)
            cat("Outliers: ",nbad,"\n")
            if(nbad > 0)
                print(ibad)
            if(full){
                cat("-------------\n")
                show(mcd)
            }
            cat("--------------------------------------------------------\n")
        }
    }

    options(digits = 5)
    set.seed(101) # <<-- sub-sampling algorithm now based on R's RNG and seed

    lname <- 20
    library(rrcov)
    method <- match.arg(method)
    if(method == "MASS")
        library(MASS)


    data(heart)
    data(starsCYG)
    data(phosphor)
    data(stackloss)
    data(coleman)
    data(salinity)
    data(wood)

    data(hbk)

    data(Animals, package = "MASS")
    brain <- Animals[c(1:24, 26:25, 27:28),]
    data(milk)
    data(bushfire)

    tmp <- sys.call()
    cat("\nCall: ", deparse(substitute(tmp)),"\n")

    cat("Data Set               n   p  Half LOG(obj)        Time\n")
    cat("========================================================\n")
    domcd(heart[, 1:2], data(heart), nrep)
    domcd(starsCYG, data(starsCYG), nrep)
    domcd(data.matrix(subset(phosphor, select = -plant)), data(phosphor), nrep)
    domcd(stack.x, data(stackloss), nrep)
    domcd(data.matrix(subset(coleman, select = -Y)), data(coleman), nrep)
    domcd(data.matrix(subset(salinity, select = -Y)), data(salinity), nrep)
    domcd(data.matrix(subset(wood, select = -y)), data(wood), nrep)
    domcd(data.matrix(subset(hbk,  select = -Y)),data(hbk), nrep)

    domcd(brain, "Animals", nrep)
    domcd(milk, data(milk), nrep)
    domcd(bushfire, data(bushfire), nrep)
    cat("========================================================\n")
}

dogen <- function(nrep=1, eps=0.49, method=c("FASTMCD", "MASS")){

    domcd <- function(x, nrep=1){
        gc()
        xtime <- system.time(dorep(x, nrep, method))[1]/nrep
        cat(sprintf("%6d %3d %10.2f\n", dim(x)[1], dim(x)[2], xtime))
        xtime
    }

    set.seed(1234)

    library(rrcov)
    library(MASS)
    method <- match.arg(method)

    ap <- c(2, 5, 10, 20, 30)
    an <- c(100, 500, 1000, 10000, 50000)

    tottime <- 0
    cat("     n   p       Time\n")
    cat("=====================\n")
    for(i in 1:length(an)) {
        for(j in 1:length(ap)) {
            n <- an[i]
            p <- ap[j]
            if(5*p <= n){
                xx <- gendata(n, p, eps)
                X <- xx$X
                tottime <- tottime + domcd(X, nrep)
            }
        }
    }

    cat("=====================\n")
    cat("Total time: ", tottime*nrep, "\n")
}

docheck <- function(n, p, eps){
    xx <- gendata(n,p,eps)
    mcd <- CovMcd(xx$X)
    check(mcd, xx$xind)
}

check <- function(mcd, xind){
##  check if mcd is robust w.r.t xind, i.e. check how many of xind
##  did not get zero weight
    mymatch <- xind %in% which(mcd@wt == 0)
    length(xind) - length(which(mymatch))
}

dorep <- function(x, nrep=1, method=c("FASTMCD","MASS")){

    method <- match.arg(method)
    for(i in 1:nrep)
    if(method == "MASS")
        cov.mcd(x)
    else
        CovMcd(x)
}

#### gendata() ####
# Generates a location contaminated multivariate
# normal sample of n observations in p dimensions
#    (1-eps)*Np(0,Ip) + eps*Np(m,Ip)
# where
#    m = (b,b,...,b)
# Defaults: eps=0 and b=10
#
gendata <- function(n,p,eps=0,b=10){

    if(missing(n) || missing(p))
        stop("Please specify (n,p)")
    if(eps < 0 || eps >= 0.5)
        stop(message="eps must be in [0,0.5)")
    X <- mvrnorm(n,rep(0,p),diag(1,nrow=p,ncol=p))
    nbad <- as.integer(eps * n)
    if(nbad > 0){
        Xbad <- mvrnorm(nbad,rep(b,p),diag(1,nrow=p,ncol=p))
        xind <- sample(n,nbad)
        X[xind,] <- Xbad
    }
    list(X=X, xind=xind)
}

pad.right <- function(z, pads)
{
### Pads spaces to right of text
    padding <- paste(rep(" ", pads), collapse = "")
    paste(z, padding, sep = "")
}

whatis<-function(x){
    if(is.data.frame(x))
        cat("Type: data.frame\n")
    else if(is.matrix(x))
        cat("Type: matrix\n")
    else if(is.vector(x))
        cat("Type: vector\n")
    else
        cat("Type: don't know\n")
}

library(rrcov)
dodata()
##doexact()
