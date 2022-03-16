# latner_2018/tables

The way to create table 4 (pg. 465) in Latex requires several steps.  

1) do ~/do_files/06_results_table_4.do
	1a) This creates ~/tables/effect_size_data_region.tex
	1b) This is the raw data

2) Copy lines 5 - 20


3) Open ~/tables/effect_size.xlsx
	3a) Paste on cell A3
	3b) Text to columns, delimited using "&"
	3c) Please note that numbers are formatted as follows: XX,XXX.XX and not XX.XXX,XX
	3d) Delete "\\" from N3:N17 using search/replace function
	3e) Copy cells P20:P34

4) Open ~/tables/effect_size_paper_region.tex
	4a) Paste on line 15
	4b) Cut lines 22 - 29, i.e. variables including and below "ARM indicator", paste below "Categorical variables" section

Authors note:  Please forgive the complicated creation of this file.  I am sure there are easier ways to do this, but this is the procedure I created at the time.  Its messy, but it works.  Also, please note that the mean in Table 4 (effect sizes) is different than the mean in Table 1 (descriptives).  The reason for this is that the descriptive statistics takes the mean of the last observation for each individual, while the effect sizes takes the mean of all observations.