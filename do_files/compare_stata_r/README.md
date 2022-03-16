# latner_2017

[![DOI:10.7910/DVN/U0RTXA](http://img.shields.io/badge/DOI-10.7910/DVN/I8QMVS.425840-B31B1B.svg)](https://doi.org/10.7910/DVN/I8QMVS)

https://doi.org/10.1111/cico.12253

## Compare Stata and R

The analysis used in the paper relies on the competing risks hazard model developed by Fine and Gray (1999) and implemented in Stata.   Since the publication of the paper, we have noticed that results will differ if users replicate the data in R.  

In R, there are several packages for implementing a competing risks hazard model.  Of these, perhaps the most common is the survival package developed and maintained by Terry Therneau (https://cran.r-project.org/web/packages/survival/index.html).  Alternatives also exist.  Dr. Therneau and colleagues raise concerns about the Fine and Gray implementation of competing risks hazard (https://cran.r-project.org/web/packages/survival/vignettes/compete.pdf).  Instead, they prefer Aalen-Johansen estimates.  Either way, their survival package does not exactly replicate Stata results.  In R, the only package that replicates Stata exactly is the KMI package.  Unfortunately, it appears as if this package is not actively maintained.  Further, unlike the survival package, KMI package is not as easy to use with post estimation commands.  Therefore, users interested in replicating this data in R should be aware of discrepancies in exact replication.  Its worth pointing out that even a simple mlogit model does not estimate identical coefficients between the two software packages.  However, in general, it is possible to qualitatively replicate the results in R using a variety of different methods.