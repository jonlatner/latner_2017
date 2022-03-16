# latner_2017

[![DOI:10.7910/DVN/U0RTXA](http://img.shields.io/badge/DOI-10.7910/DVN/I8QMVS.425840-B31B1B.svg)](https://doi.org/10.7910/DVN/I8QMVS)

https://doi.org/10.1111/cico.12253

## Introduction

Repository for the codes used for the analyses of Jonathan Latner (2017), "Rethinking the Role of Racial Segregation in the American Foreclosure Crisis."

All analyses in the article were conducted using Stata.  Complete Stata codes used are in separate .do -files.  The distinct files open the data, clean it, analyze it, and reproduce various tables and graphs.

Unfortunately, most of the underlying data used for this paper are not publicly available.  There are three types of data used for this article.  If interested in the data, please contact the author for access.

1) Loan performance data come from Corporate Trust Services (CTS), which includes information on the original balance, interest rate, credit score, and monthly loan status (current, delinquent, foreclosure, or prepayment), as well as a variety of other variables.  In the United States, after registering, data were publicly available from the web (www.ctslink.com).  This may or may not still be true.

2) Demographic data come from the Home Mortgage Disclosure Act (HMDA), which requires lenders to report the census tract of all loans issued, as well as the borrower’s race, sex, and income at time of loan application, as indicated by the primary borrower.  While HMDA data are publicly available, the HMDA data used here are restricted because it includes the actual loan number on which the data are merged together, not matched using the variables available in both datasets, as in other published journal articles (see Ghent et al. 2014 and Rugh 2015).  Data were provided by Carolina Reid PhD, who worked at the Federal Reserve Bank of San Francisco and is now a Professor of City & Regional Planning at University of California Berkeley.

3) The third source of data are foreclosure data from RealtyTrac, between 2007 and 2013.  Data were privately purchased and are not public.  While this data is not strictly necessary for analysis, it helps to confirm the degree to which CTS and merged HMDA/CTS foreclosure data are representative of national foreclosure data, at a given geographic level.  They are.  RealtyTrac compiles data from all foreclosure filings made in county court-houses to create the largest source of information on foreclosures in the United States.  RealtyTrac foreclosure data represent the universe of foreclosures in the U.S.  CTS foreclosure data represent about one-third of all subprime loans issued during the peak of subprime lending.  We compare foreclosure data from CTS to RealtyTrac to ensure that the CTS data are representative of national data.

In addition to these three main sources of data, we also supplement the data with additional data sources to create relevant variables: the 2005-2009 American Community Survey (ACS, this is used for racial segregation/isolation variables), Zillow (Zip-code-level home price index - this is used for the put option), Primary Mortgage Market Survey (PMMS) published by Freddie Mac (30 year fixed rate mortgage - this is used for the call option).  In addition, we also use two sources of publicly available housing price indices, the S&P/Case-Shiller 20 City Home Price Index and the Federal Housing Finance Authority.  Both of these are used to examine the correlation between housing price index and racial segregation (from the ACS).

The full article can be found at: https://doi.org/10.1111/cico.12253
