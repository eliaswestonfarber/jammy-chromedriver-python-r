pkg_list <- readLines("packages.txt")

# Remove any leading or trailing whitespace
pkg_list <- trimws(pkg_list)

# Remove any empty lines (if any)
pkg_list <- pkg_list[nzchar(pkg_list)]

install_if_not_present <- function(pkg) {
  if(!requireNamespace(pkg)){
    if(pkg=="cmdstanr"){
      install.packages(pkg, method='auto', repos='https://mc-stan.org/r-packages/', type="source")
    } else{
      install.packages(pkg, method='auto', repos='http://cran.us.r-project.org', type="source")
  }
}

lapply(pkg_list, install_if_not_present)
