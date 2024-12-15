-- PRIMARY KEYS
ALTER TABLE JOBS
ADD CONSTRAINT PK_JOBS PRIMARY KEY (job_id);

ALTER TABLE job_salaries
ADD CONSTRAINT PK_SALARIES PRIMARY KEY (salary_id);

ALTER TABLE job_benefits
ADD CONSTRAINT PK_BENEFITS PRIMARY KEY (job_id, type);

ALTER TABLE companies
ADD CONSTRAINT PK_COMPANIES PRIMARY KEY (company_id);

ALTER TABLE SKILLS
ADD CONSTRAINT PK_SKILLS PRIMARY KEY (skill_abr);

ALTER TABLE INDUSTRIES
ADD CONSTRAINT PK_INDUSTRIES PRIMARY KEY (industry_id);

-- DATA CLEANING AND UPDATE: HANDLING NULL VALUES AND ENSURING DATA INTEGRITY
DELETE FROM industries
WHERE industry_name IS NULL;

ALTER TABLE jobs
DROP COLUMN expiry;

ALTER TABLE jobs
DROP COLUMN currency;

UPDATE jobs
SET remote_allowed = 
    CASE
        WHEN remote_allowed IS NULL THEN 0
        ELSE 1
    END;

-- BASIC ANALYSIS
-- View all jobs
SELECT * 
FROM jobs;

-- Number of jobs
SELECT count(*)
FROM jobs;

-- Number of remote work
SELECT SUM(remote_allowed)
FROM JOBS;

-- EXPERIENCE LEVEL DISTRIBUTION AS A PERCENTAGE OF TOTAL JOB POSTINGS
CREATE VIEW Experience_Level_Distribution AS
SELECT formatted_experience_level,
       ROUND(CAST(count(*) AS FLOAT) * 100 / (SELECT count(*) FROM jobs), 3) AS [experience_level_ratio]
FROM jobs
WHERE formatted_experience_level IS NOT NULL
gROUP BY formatted_experience_level;

-- TOP 10 LOCATIONS BY NUMBER OF JOB POSTINGS
CREATE VIEW Locations_By_Job_Postings AS
SELECT location, 
       COUNT(*) AS [total]
FROM jobs
GROUP BY location;

-- APPLICATION VIEWS VS APPLIES BY EXPERIENCE LEVEL
CREATE VIEW Application_Views_By_Experience AS
SELECT formatted_experience_level, 
       ROUND(SUM(views) / SUM(applies), 3) AS [applies_rate]
FROM jobs
WHERE formatted_experience_level IS NOT NULL
GROUP BY formatted_experience_level;

-- APPLICATION TYPE SUCCESS RATE
CREATE VIEW Application_Type_Success_Rate AS
SELECT application_type, 
       ROUND(SUM(applies) / SUM(views), 3) AS [applies_rate]
FROM jobs
GROUP BY application_type;

-- MOST VIEWED AND POPULAR JOB TITLES
CREATE VIEW Job_Titles_Views AS
SELECT title, 
       COUNT(*) AS [Num_of_positions],
       SUM(views) AS [Total_views]
FROM jobs
GROUP BY title;

-- RANKING INDUSTRIES BY AVERAGE YEARLY SALARY FOR FULL-TIME POSITIONS
CREATE VIEW Ranking_Industries_By_Salary AS
SELECT ci.industry,
       AVG(j.med_salary) AS [avg_salary_Yearly]
FROM jobs j 
INNER JOIN company_industries ci 
    ON ci.company_id = j.company_id
WHERE j.pay_period = 'YEARLY' 
  AND j.med_salary IS NOT NULL 
  AND j.formatted_work_type = 'Full-time'
GROUP BY ci.industry;

-- QUARTERLY JOB POSTING TRENDS
CREATE VIEW Quarterly_Job_Posting_Trends AS
SELECT CASE 
           WHEN MONTH(original_listed_time) BETWEEN 1 AND 3 THEN 'First Quarter'
           WHEN MONTH(original_listed_time) BETWEEN 4 AND 6 THEN 'Second Quarter'
           WHEN MONTH(original_listed_time) BETWEEN 7 AND 9 THEN 'Third Quarter'
           WHEN MONTH(original_listed_time) BETWEEN 10 AND 12 THEN 'Fourth Quarter'
       END AS [quarter],
       COUNT(*) AS [Total_jobs]
FROM jobs
GROUP BY CASE 
             WHEN MONTH(original_listed_time) BETWEEN 1 AND 3 THEN 'First Quarter'
             WHEN MONTH(original_listed_time) BETWEEN 4 AND 6 THEN 'Second Quarter'
             WHEN MONTH(original_listed_time) BETWEEN 7 AND 9 THEN 'Third Quarter'
             WHEN MONTH(original_listed_time) BETWEEN 10 AND 12 THEN 'Fourth Quarter'
         END;

-- DISTRIBUTION OF POSITIONS BY EXPERIENCE LEVEL AND MONTH
CREATE VIEW Positions_Distribution_By_Month_Experience AS
SELECT formatted_experience_level,
       MONTH(original_listed_time) AS [month],
       COUNT(*) AS [number_of_positions]
FROM jobs
WHERE formatted_experience_level IS NOT NULL
GROUP BY formatted_experience_level, MONTH(original_listed_time);

-- INDUSTRIES BY NUMBER OF JOB POSTINGS
CREATE VIEW Industries_By_Job_Postings AS
SELECT i.industry_name,
       COUNT(*) AS [Num_of_positions]
FROM jobs j
INNER JOIN job_industries ji 
    ON j.job_id = ji.job_id
INNER JOIN industries i 
    ON i.industry_id = ji.industry_id
WHERE j.pay_period = 'YEARLY' 
  AND j.formatted_work_type = 'Full-time'
GROUP BY i.industry_name;

-- SALARY GAP ANALYSIS BY INDUSTRY AND EXPERIENCE LEVEL
CREATE VIEW Salary_Gap_By_Industry_Experience AS
SELECT i.industry_name, 
       j.formatted_experience_level,
       ROUND(AVG(j.max_salary) - AVG(j.min_salary), 2) AS [AVG_SALARY_GAP],
       ROUND(STDEV(j.max_salary - j.min_salary), 2) AS [Salary_gap_stddev]
FROM jobs j
INNER JOIN job_industries ji 
    ON j.job_id = ji.job_id
INNER JOIN industries i 
    ON i.industry_id = ji.industry_id
WHERE j.pay_period = 'YEARLY' 
  AND j.formatted_work_type = 'Full-time'
  AND NOT (j.formatted_experience_level IS NULL OR j.max_salary IS NULL OR j.min_salary IS NULL)
GROUP BY i.industry_name, j.formatted_experience_level;

-- NUMBER OF POSITIONS BY INDUSTRY AND EXPERIENCE LEVEL
CREATE VIEW Positions_By_Industry_Experience AS
SELECT i.industry_name, 
       j.formatted_experience_level, 
       COUNT(*) AS [Num_of_positions]
FROM jobs j
INNER JOIN job_industries ji 
    ON j.job_id = ji.job_id
INNER JOIN industries i 
    ON i.industry_id = ji.industry_id
WHERE j.formatted_experience_level IS NOT NULL
GROUP BY i.industry_name, j.formatted_experience_level;

-- AVERAGE SALARY BY INDUSTRY, EXPERIENCE LEVEL, AND LOCATION
CREATE VIEW Average_Salary_By_Industry_Experience_Location AS
SELECT i.industry_name, 
       j.formatted_experience_level, 
       j.location, 
       AVG(j.med_salary) AS [avg_salary]
FROM jobs j
INNER JOIN job_industries ji 
    ON j.job_id = ji.job_id
INNER JOIN industries i 
    ON i.industry_id = ji.industry_id
WHERE j.pay_period = 'YEARLY' 
  AND j.formatted_work_type = 'Full-time'
  AND j.formatted_experience_level IS NOT NULL 
  AND j.med_salary IS NOT NULL 
GROUP BY i.industry_name, j.formatted_experience_level, j.location;

-- COMMON SKILLS REQUIRED BY POSITIONS
CREATE VIEW Common_Skills AS
SELECT s.skill_name, 
       COUNT(*) AS [Positions]
FROM skills s 
INNER JOIN job_skills js 
    ON s.skill_abr = js.skill_abr
INNER JOIN jobs j 
    ON js.job_id = j.job_id
GROUP BY s.skill_name;
