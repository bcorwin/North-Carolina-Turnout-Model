clear all

use "/dnc/gzdata/export__analytics__natl__analytics_model_nc_20110825.dta.gz#"

set more off

*Prepping the data
gen oos = 0
	replace oos = 1 if uniform() <= .3
	
/*from demographics.do*/
*** Recoding Standard Demographic Variables With Imputation

		    
** Race and Religion dummies

* Religion
gen muslim = 0
	replace muslim = 1 if cpm_religion=="M"

gen protestant = 0
	replace protestant = 1 if cpm_religion=="P"

gen catholic = 0
	replace catholic = 1 if cpm_religion=="C"

gen jewish = 0
	replace jewish = 1 if cpm_religion=="J"

* Race -- perhaps change with source versus modeled, confidence levels
gen black = 0
	replace black = 1 if combinedethnicity=="B"

gen hispanic = 0
	replace hispanic = 1 if combinedethnicity=="H"

gen asian=0
	replace asian=1 if cpm_primary_ethnicity=="A" & black==0 & hispanic ==0

gen white = 0
	replace white = 1 if cpm_primary_ethnicity =="C" & black ==0 & hispanic == 0


** Age 

* Registration Year from Registration Date
gen reg_year=substr(registration_date,1,4)
	destring reg_year, replace

* Capped Registration Year
gen reg_year_cap47=reg_year
	replace reg_year_cap47=1947 if reg_year<1947

* Age imputation 
gen age_full = age 

gen tv_vote9600 = vote_g1996*vote_g2000

gen tv_hhavgage2 = ((hhavgage*hhvoters) - age)/(hhvoters-1) if hhvoters>1 & hhvoters!=.
	replace tv_hhavgage2 = hhavgage if age==.

reg age vote_g2006 vote_g2006_inelig ///
	vote_g2004 vote_g2004_inelig vote_g2002 vote_g2002_inelig ///
	vote_g2000 vote_g2000_ineli vote_g1998_ineli vote_g1996 vote_g1996_ineli /// 
	tv_vote9600 tv_hhavgage2 consumer_null if hhvoters>1 & hhvoters~=.
   
predict tv 
	replace age_full = tv if hhvoters>1 & hhvoters~=. & age_full==. 
	drop tv 

reg age vote_g2006 vote_g2006_inelig vote_g2004 ///
	vote_g2004_inelig vote_g2002 vote_g2002_inelig ///
    	vote_g2000 vote_g2000_ineli vote_g1998_ineli vote_g1996 vote_g1996_ineli /// 
    	tv_vote9600  consumer_null reg_year_cap47
   
predict tv 
	replace age_full = tv if age_full==. 
	drop tv 
	drop tv_vote9600
	drop tv_hhavgage2

gen tv = 58
	replace age_full = tv if age_full==.
	replace age_full = 18 if age_full<18 & age_full!=.
	replace age_full = 108 if age_full>108 & age_full!=.
	drop tv

* Rounding Off Estimates
replace age_full=round(age_full)

* Age Squared
gen age_full2=age_full^2

* Time Variant Age
gen age08=age_full-2
	replace age08=18 if age08<18 &  vote_g2008_ineligibile==0
	
gen age12 = age_full+2 
gen age12_sq=age12^2


gen age04 = age_full-6 

gen age06 = age_full-4

gen age08_sq=age08^2

* Age Buckets 2008
gen age08_1825 = 0
	replace age08_1825=1 if age08>17 & age08<26

gen age08_2635=0
	replace age08_2635=1 if age08>25 & age08<36

gen age08_3645=0
	replace age08_3645=1 if age08>35 & age08<46

gen age08_4655=0
	replace age08_4655=1 if age08>45 & age08<56

gen age08_5665=0
	replace age08_5665=1 if age08>55 & age08<66

gen age08_6675=0
	replace age08_6675=1 if age08>65 & age08<76

gen age08_over75=0
	replace age08_over75=1 if age08>75

gen age08_over65=0
	replace age08_over65=1 if age08_6675==1 | age08_over75==1


** Imputing PPI
gen ppi = consumer_ppi 

reg ppi census_medianincome_in_1000s age_full age_full2 consumer_boatownr_1 ///
	consumer_apparel_1 consumer_bankcard_1 consumer_bookmusc_1 ///
	consumer_environm_1 consumer_contbhlt_1 consumer_outdgrdn_1 ///
	consumer_electrnc_1 consumer_donrever_1 consumer_golf_1 ///
	consumer_smarstat_s consumer_smarstat_m consumer_outdoor_1 ///
	consumer_stockbnd_1 white black hispanic asian gender_female ///
	census_urbanpcnt census_suburbanpcnt census_ruralpcnt ///
	census_whitepcnt census_blackpcnt census_childrenpcnt ///
	census_singlemomspcnt census_avgtrvltime census_privateschoolpcnt ///
	census_collegepcnt census_advcnddegreepcnt census_workingwomenpcnt ///
	census_unemprate
    
predict tv    
	replace ppi = tv if ppi ==. 
	drop tv

reg ppi census_medianincome_in_1000s ln_census_medianincome ///
	census_urbanpcnt census_suburbanpcnt census_ruralpcnt ///
	census_whitepcnt census_blackpcnt census_childrenpcnt ///
	census_singlemomspcnt census_avgtrvltime census_privateschoolpcnt ///
	census_collegepcnt census_advcnddegreepcnt census_workingwomenpcnt ///
	census_unemprate

predict tv
	replace ppi = tv if ppi ==. 
	drop tv

reg ppi census_medianincome_in_1000s census_urbanpcnt census_suburbanpcnt census_ruralpcnt census_whitepcnt census_blackpcnt census_avgtrvltime ///
	census_collegepcnt census_advcnddegreepcnt census_workingwomenpcnt census_unemprate

predict tv
	replace ppi = tv if ppi == .
	drop tv
        
reg ppi black white asian hispanic jewish catholic muslim age_full ruca_metro ///
	ruca_micro ruca_core ruca_high_commute
    
predict tv
	replace ppi = tv if ppi == . 
	drop tv
	replace ppi = 5000 if ppi <5000
	replace ppi = 500000 if ppi>500000
	gen ppi_k = ppi/1000


** Percent College Graduates
gen college=census_collegepcnt
reg census_collegepcnt ruca_metro ruca_micro ruca_core
predict tv
	replace college = tv if college == .
	drop tv

** Urban Percent (mean plugged)
gen urbanpcnt_mean=census_urbanpcnt
egen tv=mean(census_urbanpcnt)
	replace urbanpcnt_mean=tv if urbanpcnt_mean==.
	drop tv

** Rural Percent (mean plugged)
gen ruralpcnt_mean=census_ruralpcnt
egen tv=mean(census_ruralpcnt)
	replace ruralpcnt_mean=tv if ruralpcnt_mean==.
	drop tv

** Suburban Percent (mean plugged)
gen suburbanpcnt_mean=census_suburbanpcnt
egen tv=mean(census_suburbanpcnt)
	replace suburbanpcnt_mean=tv if suburbanpcnt_mean==.
	drop tv

** Advance Degree (mean plugged)
gen advcnddegreepcnt_mean=census_advcnddegreepcnt
	egen tv=mean(census_advcnddegreepcnt)
	replace advcnddegreepcnt_mean=tv if advcnddegreepcnt_mean==.
	drop tv

** Median HH Income (1,000s)(mean plugged)
gen medinc_k_mean=census_medianincome_in_1000s
	egen tv=mean(census_medianincome_in_1000s)
	replace medinc_k_mean=tv if medinc_k_mean==.
	drop tv

** Unemployment (mean plugged)
gen unemprate_mean=census_unemprate
	egen tv=mean(census_unemprate)
	replace unemprate_mean=tv if unemprate_mean==.
	drop tv

** Black Percent (mean plugged)
gen blackpcnt_mean=census_blackpcnt
	egen tv=mean(census_blackpcnt)
	replace blackpcnt_mean=tv if blackpcnt_mean==.
	drop tv

** Hispanic Percent (mean plugged)
gen hisppcnt_mean=census_hisppcnt
	egen tv=mean(census_hisppcnt)
	replace hisppcnt_mean=tv if hisppcnt_mean==.
	drop tv

** Single Person Household 
gen hh_single = 0
	replace hh_single = 1 if hhvoters==1

** Unknown Ideology
gen ideology_u=0
	replace ideology_u=1 if consumer_life_conservative==0 & consumer_life_liberal==0

* Previous Voter in Household by Year
gen hh_vote_g2004_other=0
	replace hh_vote_g2004_other=1 if hh_vote_g2004_num_all>0

gen hh_vote_g2006_other=0
	replace hh_vote_g2006_other=1 if hh_vote_g2006_num_all

gen hh_vote_g0406_other=hh_vote_g2004_other*hh_vote_g2006_other

** Ineligibile with Voter in Household
gen inelig04_hhothervoter=vote_g2004_ineligibile*hh_vote_g2004_other
gen inelig06_hhothervoter=vote_g2006_ineligibile*hh_vote_g2006_other
gen inelig_0406_hhothervoter=inelig04_hhothervoter*inelig06_hhothervoter

** Ever Voted in a Primary, 2000-2006
gen primary_ever_0006=0
	replace primary_ever_0006=1 if vote_p2006==1 | vote_p2004==1 | vote_pp2004==1 | vote_p2002==1 | vote_p2001==1 | vote_pp2000==1 | vote_pp2000==1 

gen pprimary_ever_9604=0
	replace pprimary_ever_9604=1 if vote_pp2004==1 | vote_pp2000==1 | vote_pp1996==1

gen pprimary_ever_elig=0
	replace pprimary_ever_elig=1 if vote_pp2004_ineligibile==0 | vote_pp2000_ineligibile==0 | vote_pp1996_ineligibile==0

** Newly Eligibile Voter in 2008
gen newly_elig08=0
	replace newly_elig08=1 if age08>17 & age08<20

** Newly Eligibile Voter in 2012
gen newly_elig12=0
	replace newly_elig12=1 if age12>17 & age12<20

** Newly Eligibile Voter in 2004
gen newly_elig04=0
	replace newly_elig04=1 if age04>17 & age04<20

** Newly Eligibile Voter in 2006
gen newly_elig06=0
	replace newly_elig06=1 if age06>17 & age06<20


** Last Time IDed

* 2008
gen last_id_2008=0
	replace last_id_2008=1 if all_2008_num_of_resp>0

* 2006
gen last_id_2006=0 
	replace last_id_2006=1 if all_2006_num_of_resp>0 & last_id_2008==0

* 2004
gen last_id_2004=0
	replace last_id_2004=1 if all_2004_num_of_resp>0 & last_id_2008==0 & last_id_2006==0

* 2008
gen hh_last_id_2008=0
	replace hh_last_id_2008=1 if hh_all_2008_num_of_resp>0

* 2006
gen hh_last_id_2006=0 
	replace hh_last_id_2006=1 if hh_all_2006_num_of_resp>0 & hh_last_id_2008==0

* 2004
gen hh_last_id_2004=0
	replace hh_last_id_2004=1 if hh_all_2004_num_of_resp>0 & hh_last_id_2008==0 & hh_last_id_2006==0

* 2008
gen any_last_id_2008=0
	replace any_last_id_2008=1 if last_id_2008==1 | hh_last_id_2008==1

* 2006
gen any_last_id_2006=0 
	replace any_last_id_2006=1 if last_id_2006==1 | hh_last_id_2006==1

* 2004
gen any_last_id_2004=0
	replace any_last_id_2004=1 if last_id_2004==1 | hh_last_id_2004==1

* Any ID Ever
gen any_ever_id=0
	replace any_ever_id=1 if hh_all_ay_num_of_resp>0 | all_ay_num_of_resp>0

** Pre 2004 Voter
gen pre04_voter=0
	replace pre04_voter=1 if vote_g2003==1 | vote_g2002==1 | vote_g2001==1 | vote_g2000==1 | vote_g1998==1 | vote_g1996==1

** Pre 2004 Eligible
gen pre04_elig=0
	replace pre04_elig=1 if vote_g2003_ineligibile==0 | vote_g2002_ineligibile==0 | vote_g2001_ineligibile==0| vote_g2000_ineligibile==0 | ///
	vote_g1998_ineligibile==0 | vote_g1996_ineligibile==0

** Updating Registration Date Variables
gen regdate=date(registration_date, "YMD")
format regdate %d

* Registration Date Since 2006
gen regdate_since06=0
	replace regdate_since06=1 if regdate>date("2006-12-01", "YMD") & regdate<date("2008-12-01", "YMD")

gen election08 = date("2008-11-04", "YMD")

gen days_regbefore = election08-regdate 


** First Eligible

* 2004
gen first_elig04=0
	replace first_elig04=1 if vote_g2004_ineligibile==0 & vote_g2002_ineligibile==1 & vote_g2000_ineligibile==1 & ///
	vote_g1998_ineligibile==1 & vote_g1996_ineligibile==1 

* 2008
gen first_elig08=0
	replace first_elig08=1 if vote_g2008_ineligibile==0 & vote_g2004_ineligibile==1 & vote_g2002_ineligibile==1 & vote_g2000_ineligibile==1 & ///
	vote_g1998_ineligibile==1 & vote_g1996_ineligibile==1 
	

** Interaction

* Vote in both 2004 and 2006
gen vote_g0406=vote_g2004*vote_g2006

* Vote in neither 2004 nor 2006 (but eligible)
gen novote_g0406_elig=vote_g2006_novote_eligibile*vote_g2004_novote_eligibile

* Voted in 2004 but not 2006 (but eligible)
gen vote_g04_novote_g06_elig=vote_g2004*vote_g2006_novote_eligibile

* Vote in 2004 and Pre 2004
gen vote_g04_pre04=vote_g2004*pre04_voter

* Vote in 2006 and Pre 2004
gen vote_g06_pre04=vote_g2006*pre04_voter

* Vote in 2004 and Primary Ever
gen vote_g04_prim_ever=vote_g2004*primary_ever_0006

* Vote in 2006 and Primary Ever
gen vote_g06_prim_ever=vote_g2006*primary_ever_0006

* Vote Pre 2004 and Primary Ever
gen pre04_primary_ever=pre04_voter*primary_ever_0006

* Unemployment for Young People
gen unemprate_1825=age08_1825*unemprate_mean

* Vote in 2006 and newly eligible
gen vote_g06_newly_elig06=newly_elig06*vote_g2006

* Black Woman
gen black_woman=black*gender_female

* Presidential Voter
gen pres_voter_0004=vote_g2000*vote_g2004

* Midterm Voter
gen mterm_voter_0206=vote_g2002*vote_g2006

gen mterm_never_0206=vote_g2002_novote_eligibile*vote_g2006_novote_eligibile

* Presidential Only Voter
gen pres_only_0006=0
	replace pres_only_0006=1 if vote_g2004==1 & vote_g2000==1 & vote_g2006==0 & vote_g2002==0

* Never Presidential Voter
gen pres_never_0004_elig=vote_g2004_novote_eligibile*vote_g2000_novote_eligibile

* Vote in 2006 Primary and General
gen vote_pg2006=vote_p2006*vote_g2006

* Pre 2006 Voter
gen pre06_voter=0
	replace pre06_voter=1 if vote_g2005==1 | vote_g2004==1 | vote_g2003==1 | vote_g2002==1 | vote_g2001==1 | vote_g2000==1 | vote_g1998==1 | vote_g1996==1

* Newly Eligible Since 2006
gen newly_elig_since06=0
	replace newly_elig_since06=1 if age06<=17

* Vote 2005 and 2006
gen vote_g0506=vote_g2005*vote_g2006

* Vote 2005 and Pre 2004
gen vote_g05_pre04=vote_g2005*pre04_voter

* No Vote in 2006 but HH Voter
gen hh_vote_g06_novote=hh_vote_g2006_other*vote_g2006_novote_eligibile

* Married Woman
gen married_woman=consumer_smarstat_m*gender_female

* Young Woman
gen young_woman=gender_female*age08_1825


* Gender by Age
#delimit ; 
foreach var of varlist age08_1825 age08_2635 age08_3645
		       age08_4655 age08_5665 age08_6675 age08_over75 {;
	gen woman_`var' = gender_female*`var';
	};

#delimit cr 

* Vote 2005 and Primary 2006
gen vote_g05_p06=vote_p2006*vote_g2005

* No vote in 2005 and 2006
gen novote_g0506_elig=vote_g2006_novote_eligibile*vote_g2005_novote_eligibile


*Rural/Urban/Other*

gen urban = 0 
gen rural = 0 
gen other_ruca = 0 

destring ruca_primary, replace
replace urban = 1 if ruca_primary < 4 
replace rural = 1 if ruca_primary == 10 
replace other_ruca = 1 if urban == 0 & rural == 0 
/*End of demographics.do*/

**Means plugging
***Industry information
gen farmingprct_mean = census_i_farmingprct
egen temp = mean(census_i_farmingprct), by (us_cong_district)
	replace farmingprct_mean = temp if farmingprct_mean == .
	drop temp
	
gen miningprct_mean = census_i_miningprct
egen temp = mean(census_i_miningprct), by (us_cong_district)
	replace miningprct_mean = temp if miningprct_mean == .
	drop temp
	
gen manufacturingprct_mean = census_i_manufacturingprct
egen temp = mean(census_i_manufacturingprct), by (us_cong_district)
	replace manufacturingprct_mean = temp if manufacturingprct_mean == .
	drop temp

gen finan_realest_srvsprct_mean = census_i_finan_realest_srvsprct
egen temp = mean(census_i_finan_realest_srvsprct), by (us_cong_district)
	replace finan_realest_srvsprct_mean = temp if finan_realest_srvsprct_mean == .
	drop temp

** Aggregated Turnout

* By CD
egen cd_turnout04= mean(vote_g2004), by(us_cong_district)
egen cd_turnout06= mean(vote_g2006), by(us_cong_district)
egen cd_turnout08= mean(vote_g2008), by(us_cong_district)

* By Precinct 
egen pre_turnout04= mean(vote_g2004), by(precinct_id)
egen pre_turnout06= mean(vote_g2006), by(precinct_id)
egen pre_turnout08= mean(vote_g2008), by(precinct_id)

gen religion_p = 0
	replace religion_p = 1 if cpm_religion == "P"
gen religion_x = 0
	replace religion_x = 1 if cpm_religion == "X"
gen religion_m = 0
	replace religion_m = 1 if cpm_religion == "M"
gen religion_c = 0
	replace religion_c = 1 if cpm_religion == "C"

**Type of voter
gen old_voter_04 = 0 //Voted in 2004 and in at least one even year election previously
	replace old_voter_04 = 1 if vote_g2004 == 1 & (vote_g2002 == 1 | vote_g2000 == 1 | vote_g1998 == 1 | vote_g1996 == 1)
gen new_voter_04 = 0 //Voted in 2004 but never before in an even year election
	replace new_voter_04 = 1 if old_voter_04 == 0
/* not needed, just notes to myself
gen non_voter_04 = 0 //Didn't vote in 2004 and was eligible to
	replace non_voter_04 = 1 if vote_g2004 == 0 & vote_g2004_ineligibile == 0
gen inelig_voter_04
	replace inelig_voter04 = 1 if vote_g2004_ineligibile == 1
*/

**Odd year election voting
gen pre_g08_oddyear = 0
	replace pre_g08_oddyear = 1 if vote_g2007 == 1 | vote_g2005 == 1 | vote_g2003 == 1 | vote_g2001 == 1
**Primary election voting
gen pre_p08_even= 0
	replace pre_p08_even = 1 if vote_p2006 == 1 | vote_p2004 == 1 | vote_p2002 == 1 | vote_p2000 == 1 | vote_p1998 == 1 | vote_p1996 == 1

**Interactions
gen married_female = consumer_smarstat_m*gender_female
gen vote_p0408 = 0
	replace vote_p0408 = 1 if vote_p2008 == 1 | vote_p2004 == 1

*Model building for ineligble in 2004
logit vote_g2008 age08_1825 age08_2635 age08_4655 age08_5665 age08_6675 age08_over75 ///
	gender_female consumer_smarstat_m married_female ///
	if vote_g2008_ineligibile == 0 & vote_g2004_ineligibile == 1 & oos == 0
	
logit vote_g2008 age08_1825 age08_2635 age08_4655 age08_5665 age08_6675 age08_over75 ///
	gender_female consumer_smarstat_m married_female ///
	cd_turnout04 prec_turnout04 ///
	if vote_g2008_ineligibile == 0 & vote_g2004_ineligibile == 1 & oos == 0
	
logit vote_g2008 age08_1825 age08_2635 age08_4655 age08_5665 age08_6675 age08_over75 ///
	gender_female consumer_smarstat_m married_female ///
	cd_turnout04 ///
	urbanpcnt_mean ruralpcnt_mean ///
	if vote_g2008_ineligibile == 0 & vote_g2004_ineligibile == 1 & oos == 0
	
logit vote_g2008 age08_1825 age08_2635 age08_4655 age08_5665 age08_6675 age08_over75 ///
	gender_female consumer_smarstat_m married_female ///
	cd_turnout04 ///
	urbanpcnt_mean ruralpcnt_mean ///
	farmingprct_mean miningprct_mean manufacturingprct_mean ///
	if vote_g2008_ineligibile == 0 & vote_g2004_ineligibile == 1 & oos == 0

logit vote_g2008 age08_1825 age08_2635 age08_4655 age08_5665 age08_6675 age08_over75 ///
	gender_female consumer_smarstat_m married_female ///
	cd_turnout04 ///
	urbanpcnt_mean ruralpcnt_mean ///
	farmingprct_mean manufacturingprct_mean ///
	if vote_g2008_ineligibile == 0 & vote_g2004_ineligibile == 1 & oos == 0

logit vote_g2008 age08_1825 age08_2635 age08_4655 age08_5665 age08_6675 age08_over75 ///
	gender_female consumer_smarstat_m married_female ///
	cd_turnout04 hhvoters ///
	urbanpcnt_mean ruralpcnt_mean ///
	farmingprct_mean manufacturingprct_mean finan_realest_srvsprct_mean ///
	if vote_g2008_ineligibile == 0 & vote_g2004_ineligibile == 1 & oos == 0

logit vote_g2008 age08_1825 age08_2635 age08_4655 age08_5665 age08_6675 age08_over75 ///
	gender_female consumer_smarstat_m married_female ///
	cd_turnout04 hhvoters ///
	urbanpcnt_mean ruralpcnt_mean hisppcnt_mean ///
	farmingprct_mean manufacturingprct_mean finan_realest_srvsprct_mean ///
	if vote_g2008_ineligibile == 0 & vote_g2004_ineligibile == 1 & oos == 0
	
logit vote_g2008 age08_1825 age08_2635 age08_4655 age08_5665 age08_6675 age08_over75 ///
	gender_female consumer_smarstat_m married_female ideology_u ///
	cd_turnout04 hhvoters ///
	urbanpcnt_mean ruralpcnt_mean hisppcnt_mean ///
	farmingprct_mean manufacturingprct_mean finan_realest_srvsprct_mean ///
	if vote_g2008_ineligibile == 0 & vote_g2004_ineligibile == 1 & oos == 0
	
logit vote_g2008 age08_1825 age08_2635 age08_4655 age08_5665 age08_6675 age08_over75 ///
	gender_female consumer_smarstat_m married_female ideology_u ///
	religion_p religion_x religion_m religion_c ///
	cd_turnout04 hhvoters ///
	urbanpcnt_mean ruralpcnt_mean hisppcnt_mean ///
	farmingprct_mean manufacturingprct_mean finan_realest_srvsprct_mean ///
	if vote_g2008_ineligibile == 0 & vote_g2004_ineligibile == 1 & oos == 0
	
logit vote_g2008 age08_1825 age08_2635 age08_4655 age08_5665 age08_6675 age08_over75 ///
	vote_p2008 ///
	gender_female consumer_smarstat_m married_female ideology_u ///
	religion_p religion_x religion_m religion_c ///
	cd_turnout04 hhvoters ///
	urbanpcnt_mean ruralpcnt_mean hisppcnt_mean ///
	farmingprct_mean manufacturingprct_mean finan_realest_srvsprct_mean ///
	if vote_g2008_ineligibile == 0 & vote_g2004_ineligibile == 1 & oos == 0

*Validation for ineligble in 2004
drop vote_prob vote_prob_dec
predict vote_prob if vote_g2008_ineligibile == 0 & vote_g2004_ineligibile == 1, pr
xtile vote_prob_dec = vote_prob if vote_g2008_ineligibile == 0, n(10)
tabstat vote_prob vote_g2008 if oos == 1, by(vote_prob_dec) statistics(mean, count)
hist vote_prob if vote_g2008_ineligibile == 0, bin(100) freq name(inelig_hist, replace) ///
	title(North Carolina) subtitle(Not eligible to vote 2004)
graph bar (mean) vote_prob vote_g2008 if vote_g2008_ineligibile == 0 & vote_g2004_ineligibile == 1, over(vote_prob_dec) name(inelig_bar, replace) ///
	title(North Carolina) subtitle(Not eligible to vote 2004)
	
*Model building for new voters in 2004
logit vote_g2008 age08_1825 age08_2635 age08_4655 age08_5665 age08_6675 age08_over75 ///
	if vote_g2008_ineligibile == 0 & new_voter_04 == 1 & oos == 0

logit vote_g2008 age08_1825 age08_2635 age08_4655 age08_5665 age08_6675 age08_over75 ///
	pre_g08_oddyear pre_p08_even ///
	if vote_g2008_ineligibile == 0 & new_voter_04 == 1 & oos == 0
	
logit vote_g2008 age08_1825 age08_2635 age08_4655 age08_5665 age08_6675 age08_over75 ///
	pre_g08_oddyear ///
	gender_female consumer_smarstat_m married_female ///
	if vote_g2008_ineligibile == 0 & new_voter_04 == 1 & oos == 0
	
logit vote_g2008 age08_1825 age08_2635 age08_4655 age08_5665 age08_6675 age08_over75 ///
	pre_g08_oddyear vote_p2008 vote_p2004 vote_p0408 ///
	gender_female consumer_smarstat_m married_female ///
	if vote_g2008_ineligibile == 0 & new_voter_04 == 1 & oos == 0

logit vote_g2008 age08_1825 age08_2635 age08_4655 age08_5665 age08_6675 age08_over75 ///
	pre_g08_oddyear vote_p2008 vote_p2004 vote_p0408 ///
	gender_female consumer_smarstat_m married_female ideology_u ///
	if vote_g2008_ineligibile == 0 & new_voter_04 == 1 & oos == 0
	
logit vote_g2008 age08_1825 age08_2635 age08_4655 age08_5665 age08_6675 age08_over75 ///
	pre_g08_oddyear vote_p2008 vote_p2004 vote_p0408 ///
	religion_p religion_x religion_c ///
	gender_female consumer_smarstat_m married_female ideology_u ///
	if vote_g2008_ineligibile == 0 & new_voter_04 == 1 & oos == 0

logit vote_g2008 age08_1825 age08_2635 age08_4655 age08_5665 age08_6675 age08_over75 ///
	pre_g08_oddyear vote_p2008 vote_p2004 vote_p0408 ///
	gender_female consumer_smarstat_m married_female ideology_u ///
	religion_p religion_x religion_c ///
	cd_turnout04 hhvoters ///
	if vote_g2008_ineligibile == 0 & new_voter_04 == 1 & oos == 0
	
logit vote_g2008 age08_1825 age08_2635 age08_4655 age08_5665 age08_6675 age08_over75 ///
	pre_g08_oddyear vote_p2008 vote_p2004 vote_p0408 ///
	gender_female consumer_smarstat_m married_female ideology_u ///
	religion_p religion_x religion_c ///
	cd_turnout04 hhvoters ///
	urbanpcnt_mean ruralpcnt_mean hisppcnt_mean ///
	farmingprct_mean manufacturingprct_mean finan_realest_srvsprct_mean ///
	if vote_g2008_ineligibile == 0 & new_voter_04 == 1 & oos == 0

*Validation for new voters in 2004
drop vote_prob vote_prob_dec
predict vote_prob if vote_g2008_ineligibile == 0 & new_voter_04 == 1, pr
xtile vote_prob_dec = vote_prob if vote_g2008_ineligibile == 0, n(10)
//tabstat vote_prob vote_g2008 if oos == 1, by(vote_prob_dec) statistics(mean, count)
hist vote_prob if vote_g2008_ineligibile == 0, bin(100) freq name(new_hist, replace) ///
	title(North Carolina) subtitle(New voters in  2004)
graph bar (mean) vote_prob vote_g2008 if vote_g2008_ineligibile == 0 & new_voter_04 == 1, over(vote_prob_dec) name(new_bar, replace) ///
	title(North Carolina) subtitle(New voters in 2004)

*Model building for non-voters in 2004
logit vote_g2008 age08_1825 age08_2635 age08_4655 age08_5665 age08_6675 age08_over75 ///
	if vote_g2008_ineligibile == 0 & vote_g2004 == 0 & oos == 0

*Validation for non-voters in 2004
drop vote_prob vote_prob_dec
predict vote_prob if vote_g2008_ineligibile == 0 & non_voter_04 == 1, pr
xtile vote_prob_dec = vote_prob if vote_g2008_ineligibile == 0, n(10)
//tabstat vote_prob vote_g2008 if oos == 1, by(vote_prob_dec) statistics(mean, count)
hist vote_prob if vote_g2008_ineligibile == 0, bin(100) freq name(non_hist, replace) ///
	title(North Carolina) subtitle(Non-voters in  2004)
graph bar (mean) vote_prob vote_g2008 if vote_g2008_ineligibile == 0 & non_voter_04 == 1, over(vote_prob_dec) name(non_bar, replace) ///
	title(North Carolina) subtitle(Non voters in 2004)

*Model building for old voters in 2004
*Validation for old voters in 2004
