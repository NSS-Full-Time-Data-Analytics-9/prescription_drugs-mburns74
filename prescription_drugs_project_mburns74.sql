-- 1. 
--     a. Which prescriber had the highest total number of claims (totaled over all drugs)? 
--Report the npi and the total number of claims.

SELECT npi AS prescriber,
total_claim_count AS highest_total_claim_count
FROM prescription
ORDER BY highest_total_claim_count DESC
LIMIT 1;
--Answer: npi 1912011792 Count: 4538

    
--     b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  
--specialty_description, and the total number of claims.

SELECT prescriber.nppes_provider_first_name AS provider_first_name,
prescriber.nppes_provider_last_org_name AS provider_last_name,
prescriber.specialty_description AS spec_description,
prescription.total_claim_count AS total_claims
FROM prescription
INNER JOIN prescriber
USING(npi)
ORDER BY total_claims DESC
LIMIT 1;
--Answer: David Coffey Family Practice 4538


-- 2. 
--     a. Which specialty had the most total number of claims (totaled over all drugs)?

SELECT DISTINCT(prescriber.specialty_description) AS specialty_name,
SUM(prescription.total_claim_count) AS total_claims
FROM prescription
INNER JOIN prescriber
USING (npi)
GROUP BY prescriber.specialty_description
ORDER BY total_claims DESC;
--Answer: Family Practice SUM: 9752347


--     b. Which specialty had the most total number of claims for opioids?

SELECT DISTINCT(prescriber.specialty_description) AS specialty_name,
	SUM(prescription.total_claim_count) AS total_claims,
	drug.opioid_drug_flag AS opioid_Y_or_N
FROM prescription
	INNER JOIN prescriber
	USING (npi)
		INNER JOIN drug
		ON prescription.drug_name=drug.drug_name
WHERE drug.opioid_drug_flag = 'Y'
GROUP BY prescriber.specialty_description, drug.opioid_drug_flag
ORDER BY total_claims DESC;
--Answer: Nurse Practitioner

--     c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no 
--associated prescriptions in the prescription table?

--Based on information provided total_claim_count– The number of Medicare Part D claims. This includes original prescriptions and 
--refills. Aggregated records based on total_claim_countfewer than 11 are not included in the data file
-- bene_count– The total number of unique Medicare Part D beneficiarieswith at least one claim for the 
-- drug. Counts fewer than 11 are suppressed and are indicated by a blank.

SELECT DISTINCT(prescriber.specialty_description) As specialty_name,
	prescription.total_claim_count
FROM prescriber
	FULL JOIN prescription
USING(npi)
WHERE prescription.total_claim_count IS NULL


--     d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* 
--For each specialty, report the percentage of total claims by that specialty which are for opioids. 
--Which specialties have a high percentage of opioids?

SELECT DISTINCT(prescriber.specialty_description) AS specialty_name,
	ROUND(COUNT(prescription.total_claim_count)/SUM(prescription.total_claim_count)*100,2) AS percentage_total_claims,
	drug.opioid_drug_flag AS opioid_Y_or_N
FROM prescription
	INNER JOIN prescriber
	USING (npi)
		INNER JOIN drug
		ON prescription.drug_name=drug.drug_name
WHERE drug.opioid_drug_flag = 'Y'
GROUP BY prescriber.specialty_description, drug.opioid_drug_flag
ORDER BY percentage_total_claims DESC;

-- 3. 
--     a. Which drug (generic_name) had the highest total drug cost?

SELECT drug.generic_name,
	SUM(prescription.total_drug_cost) AS total_generic_drug_cost
FROM drug
	INNER JOIN prescription
	USING(drug_name)
GROUP BY drug.generic_name
ORDER BY total_generic_drug_cost DESC;
--Answer: Insulin


--     b. Which drug (generic_name) has the hightest total cost per day? 

SELECT drug.generic_name, 
	SUM(prescription.total_drug_cost)/(prescription.total_day_supply) AS total_day_cost
FROM drug
	INNER JOIN prescription
	USING(drug_name)
GROUP BY drug.generic_name, prescription.total_day_supply
ORDER BY total_day_cost DESC;
--Answer: Ledipasvir/Sofosbuvir

--**Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**

SELECT drug.generic_name, 
	ROUND(SUM(prescription.total_drug_cost)/(prescription.total_day_supply),2) AS total_day_cost
FROM drug
	INNER JOIN prescription
	USING(drug_name)
GROUP BY drug.generic_name, prescription.total_day_supply
ORDER BY total_day_cost DESC;

-- 4. 
--     a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 
--'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs 
--which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.

SELECT drug_name, 
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	WHEN antibiotic_drug_flag = 'Y' THEN 'antibiodic'
	ELSE 'neither' END AS drug_type
FROM drug;


--     b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) 
--on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.

SELECT SUM(CASE WHEN opioid_drug_flag = 'Y' THEN prescription.total_drug_cost::money END) AS opioid_total_cost,
		SUM( CASE WHEN antibiotic_drug_flag = 'Y' THEN prescription.total_drug_cost::money END) AS antibiotic_total_cost
FROM drug
	INNER JOIN prescription
	USING(drug_name);
--ANSWER: Opioid Total $105 million, Antibiotic $38.4 million

-- 5. 
--     a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, 
--not just Tennessee.

SELECT COUNT(DISTINCT cbsa) AS cbsa_in_tn
FROM cbsa
WHERE cbsaname LIKE '%TN%'
--ANSWER: 10

--     b. Which cbsa has the largest combined population? Which has the smallest? 
--Report the CBSA name and total population.

--I asked instructors largest and smallest in TN only as above in part A and they said "TN only" for questions 5B & 5C

SELECT DISTINCT cbsa.cbsaname AS cbsa_name,
	SUM(population.population) AS total_population
FROM cbsa
	INNER JOIN fips_county
	USING(fipscounty)
		INNER JOIN population
		USING (fipscounty)
WHERE cbsaname LIKE '%TN%'
GROUP BY cbsa.cbsaname
ORDER BY total_population DESC
--ANSWER: Largest - Nashville-Davidson, Smallest - Morristown


--     c. What is the largest (in terms of population) county which is not included in a CBSA? 
--Report the county name and population.

SELECT DISTINCT fips_county.county AS county_name,
SUM(population.population) AS total_population
FROM fips_county
	FULL JOIN cbsa
	USING(fipscounty)
		FULL JOIN population
		USING(fipscounty)
WHERE fips_county.state LIKE 'TN' AND cbsa.cbsa IS NULL
GROUP BY fips_county.county
ORDER BY total_population DESC;
--ANSWER: Sevier County, Total_population 95523



-- 6. 
--     a. Find all rows in the prescription table where total_claims is at least 3000. 
--Report the drug_name and the total_claim_count.


SELECT DISTINCT drug_name AS name_of_drug, prescription.total_claim_count
FROM prescription
WHERE prescription.total_claim_count >= 3000
GROUP BY drug_name,prescription.total_claim_count;

--     b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

SELECT prescription.drug_name, 
	total_claim_count,
	drug.opioid_drug_flag
FROM prescription
	LEFT JOIN drug
	USING(drug_name)
WHERE prescription.total_claim_count >= 3000 AND drug.opioid_drug_flag =  'Y'


--     c. Add another column to you answer from the previous part which gives the prescriber first 
--and last name associated with each row.

SELECT prescriber.nppes_provider_first_name AS first_name,
	prescriber.nppes_provider_last_org_name AS last_name,
	prescription.drug_name, 
	total_claim_count,
	drug.opioid_drug_flag
FROM prescription
	LEFT JOIN drug
	USING(drug_name)
		INNER JOIN prescriber
		USING (npi)
WHERE prescription.total_claim_count >= 3000 AND drug.opioid_drug_flag =  'Y'

-- 7. The goal of this exercise is to generate a full list of all pain management specialists in 
--Nashville and the number of claims they had for each opioid. 
--**Hint:** The results from all 3 parts will have 637 rows.

--     a. First, create a list of all npi/drug_name combinations for pain management specialists 
--(specialty_description = 'Pain Managment') in the city of Nashville (nppes_provider_city = 'NASHVILLE'), 
--where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** 
--Double-check your query before running it. 
--You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.

SELECT p1.npi, p2.drug_name,p1.nppes_provider_city,p1.specialty_description,d.opioid_drug_flag
FROM prescriber AS p1
	FULL JOIN prescription AS p2
	USING(npi)
		FULL JOIN drug AS d
		USING(drug_name)
WHERE p1.specialty_description = 'Pain Management' AND p1.nppes_provider_city = 'NASHVILLE' AND opioid_drug_flag = 'Y'

--     b. Next, report the number of claims per drug per prescriber. 
--Be sure to include all combinations, whether or not the prescriber had any claims. 
--You should report the npi, the drug name, and the number of claims (total_claim_count).

SELECT p1.npi, p2.drug_name, p2.total_claim_count
FROM prescriber AS p1
	FULL JOIN prescription AS p2
	USING(npi)
		FULL JOIN drug AS d
		USING(drug_name)
WHERE p1.specialty_description = 'Pain Management' AND p1.nppes_provider_city = 'NASHVILLE' AND opioid_drug_flag = 'Y'
GROUP BY p1.npi,p2.drug_name,p2.total_claim_count
    
--     c. Finally, if you have not done so already, fill in any missing values for 
--total_claim_count with 0. Hint - Google the COALESCE function.

-- 1. How many npi numbers appear in the prescriber table but not in the prescription table?

SELECT COUNT (p1.npi)
FROM prescriber AS p1
	LEFT JOIN prescription AS p2
	ON p1.npi=p2.npi
WHERE p2.npi IS NULL
--ANSWER: 4458

-- 2.
--     a. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Family Practice.

SELECT d.generic_name,COUNT(total_claim_count) AS total_generic
FROM prescriber AS p1
	FULL JOIN prescription AS p2
	USING(npi)
		FULL JOIN drug AS d
		USING (drug_name)
WHERE p1.specialty_description = 'Family Practice'
GROUP BY d.generic_name
ORDER BY total_generic DESC
LIMIT 5;


--     b. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Cardiology.

SELECT d.generic_name,COUNT(total_claim_count) AS total_generic
FROM prescriber AS p1
	FULL JOIN prescription AS p2
	USING(npi)
		FULL JOIN drug AS d
		USING (drug_name)
WHERE p1.specialty_description = 'Cardiology'
GROUP BY d.generic_name
ORDER BY total_generic DESC
LIMIT 5;


--     c. Which drugs are in the top five prescribed by Family Practice prescribers and Cardiologists? 
--Combine what you did for parts a and b into a single query to answer this question.

SELECT d.generic_name,COUNT(total_claim_count) AS total_generic
FROM prescriber AS p1
	FULL JOIN prescription AS p2
	USING(npi)
		FULL JOIN drug AS d
		USING (drug_name)
WHERE p1.specialty_description IN ('Family Pratice','Cardiology')
GROUP BY d.generic_name
ORDER BY total_generic DESC
LIMIT 5;

-- 3. Your goal in this question is to generate a list of the top prescribers in each of the major metropolitan areas of Tennessee.
--     a. First, write a query that finds the top 5 prescribers in Nashville in terms of the total number 
--of claims (total_claim_count) across all drugs. 
--Report the npi, the total number of claims, and include a column showing the city.

SELECT p1.npi, SUM(p2.total_claim_count) AS total_number_claims,p1.nppes_provider_city
FROM prescriber AS p1
	FULL JOIN prescription AS p2
	USING (npi)
WHERE p1.nppes_provider_city = 'NASHVILLE' AND p2.total_claim_count IS NOT NULL
GROUP BY p1.npi,p1.nppes_provider_city
ORDER BY total_number_claims DESC
LIMIT 5;

    
--     b. Now, report the same for Memphis.
 
SELECT p1.npi, SUM(p2.total_claim_count) AS total_number_claims,p1.nppes_provider_city
FROM prescriber AS p1
	FULL JOIN prescription AS p2
	USING (npi)
WHERE p1.nppes_provider_city = 'MEMPHIS' AND p2.total_claim_count IS NOT NULL
GROUP BY p1.npi,p1.nppes_provider_city
ORDER BY total_number_claims DESC
LIMIT 5;
 
--     c. Combine your results from a and b, along with the results for Knoxville and Chattanooga.

SELECT p1.npi, SUM(p2.total_claim_count) AS total_number_claims,p1.nppes_provider_city
FROM prescriber AS p1
	FULL JOIN prescription AS p2
	USING (npi)
WHERE p1.nppes_provider_city IN('NASHVILLE','MEMPHIS','KNOXVILLE','CHATTANOOGA') 
AND p2.total_claim_count IS NOT NULL
GROUP BY p1.npi,p1.nppes_provider_city
ORDER BY total_number_claims DESC;


-- 4. Find all counties which had an above-average number of overdose deaths. 
--Report the county name and number of overdose deaths.

SELECT f.county,o.deaths
FROM fips_county AS f
	FULL JOIN overdoses AS o
	USING(fipscounty)
WHERE o.deaths > 
		(SELECT AVG(deaths)
		FROM overdoses);


-- 5.
--     a. Write a query that finds the total population of Tennessee.

SELECT SUM(p.population) AS total_population_tn
FROM population AS p
	FULL JOIN fips_county AS f
	USING(fipscounty)
WHERE f.state = 'TN' AND p.population IS NOT NULL;

    
--     b. Build off of the query that you wrote in part a to write a query that returns for each county that county's name, 
--its population, and the percentage of the total population of Tennessee that is contained in that county.

SELECT f.county, p.population, ROUND(p.population/(6597381),2)*100 AS percentage_of_population
FROM population AS p
	FULL JOIN fips_county AS f
	USING(fipscounty)
		FULL JOIN population AS p2
		USING(fipscounty)
WHERE f.state = 'TN' AND p.population IS NOT NULL
GROUP BY p.population,f.county,p2.population
ORDER BY p.population DESC;





