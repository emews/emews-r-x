
# INSTALL APPS
# Install key application libraries as test

# Installation settings:
r <- getOption("repos")
# Change this mirror as needed:
r["CRAN"] <- "http://cran.cnr.berkeley.edu/"
# r["CRAN"] <- "http://cran.wustl.edu/"
options(repos = r)
NCPUS = 8

PKGS <- list(
    "mgcv",
    "farver",
    "ggplot2"
)

for (pkg in PKGS) {
  print("")
  cat("INSTALL: ", pkg, "\n")
  # install.packages() does not return an error status
  install.packages(pkg, Ncpus=NCPUS, verbose=TRUE)
  print("")
  # Test that the pkg installed and is loadable
  cat("LOAD:    ", pkg, "\n")
  library(package=pkg, character.only=TRUE)
}

print("INSTALL-APPS: OK");
