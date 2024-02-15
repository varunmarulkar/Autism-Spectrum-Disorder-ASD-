use asd;
select * from data;
select count(*) from data;
desc data;

#Four Business Movement: mean,mode,median,standard deviation,variance,range,skewness,kurtosis
#1) Duration
select avg(duration) as mean from data;  #41.69775550746736
select duration as median
from(select duration,row_number() over(order by duration) as row_num,
count(*) over() as total_count
from data) as subquery
where row_num=(total_count+1)/2
or row_num=(total_count+2)/2; #median=33.13
select duration,count(*) as frequency from data group by duration order by frequency desc limit 1; #mode=1.2
select max(duration)-min(duration) from data; #129.18
select stddev(duration) as standard_deviation from data; #stddev=33.427601559666506
select variance(duration) as variance from data;  #variance=1117.4045460318187
select (sum(power(duration-(select avg(duration) from data),3))/
(count(*) * power ((select stddev(duration) from data),3))
)as skewness 
from data;  #skewness=0.6993573701712712
select(sum(power(duration-(select avg(duration)from data),4))/
(count(*) *power((select stddev(duration) from data),4))-3
) as kurtosis
from data;   #kurtosis=-0.6749837716465783

#2)probability
select avg(probability) as mean from data; #mean=0.9070679284075369
select probability as median
from(select probability,row_number() over(order by probability) as row_count,
count(*) over() as total_count from data )as subquery
where row_count=(total_count+1)/2
or row_count=(total_count+2)/2;  #median=0.9919778
select probability, count(*) as frequency from data group by probability order by frequency desc limit 1;  #mode=1
select stddev(probability) as standard_deviation from data; #stddev=0.1490171673306348
select variance(probability) as variance from data; #variance=0.02220611615924641
select max(probability) from data; #max=1
select min(probability) from data; #min=0.26886365
select max(probability)-min(probability) from data; #range=0.73113635
select (sum(power(probability-(select avg(probability) from data),3))/
(count(*) * power((select stddev(probability) from data),3))
)as skewness
from data;  #skewness=-1.6948854937904922
select (sum(power(probability-(select avg(probability) from data),4))/
(count(*) *power((select stddev(probability) from data),4))-3
)as kurtosis
from data;  #kurtosis=1.8310525510566888

#3) fps
select avg(fps) as mean from data; #mean=23.262830294620073
select fps as median
from(select fps,row_number() over(order by fps) as row_count,
count(*) over() as total_count from data
)as subquery
where row_count=(total_count+1)/2
or row_count=(total_count+2)/2;  #median=29.769
select fps,count(*) as frequency from data group by fps order by frequency desc limit 1; #mode=12.496133
select stddev(fps) as standard_deviation from data;  #stddev=8.043118561372866
select variance(fps) as variance from data; #variance=64.69175619230072
select max(fps)-min(fps) from data; #range=17.548307
select max(fps) from data; #max=30.04444
select min(fps) from data;  #min=12.496133
select (sum(power(fps-(select avg(fps) from data),3))/
(count(*)*power((select stddev(fps) from data),3))
)as skewness from data;  #-0.5157911921796091
select (sum(power(fps-(select avg(fps) from data),4))/
(count(*) *power((select stddev(fps) from data),4))-3
)as kurtosis from data;   #kurtosis=-1.6243293920946955


#missing values
select count(*) from data where duration is null;  #no null values
select count(*) from data where probability is null;  #no null values
select count(*) from data where fps is null; #no null values

#outlier detection
#1) Duration
WITH orderedList AS (
    SELECT
        duration,
        ROW_NUMBER() OVER (ORDER BY duration) AS row_n
    FROM data
),
iqr AS (
    SELECT
        duration,
        (
            SELECT duration AS quartile_break
            FROM orderedList
            WHERE row_n = FLOOR((SELECT COUNT(*) FROM data) * 0.75)
        ) AS q_three,
        (
            SELECT duration AS quartile_break
            FROM orderedList
            WHERE row_n = FLOOR((SELECT COUNT(*) FROM data) * 0.25)
        ) AS q_one,
        1.5 * (
            (
                SELECT duration AS quartile_break
                FROM orderedList
                WHERE row_n = FLOOR((SELECT COUNT(*) FROM data) * 0.75)
            ) - (
                SELECT duration AS quartile_break
                FROM orderedList
                WHERE row_n = FLOOR((SELECT COUNT(*) FROM data) * 0.25)
            )
        ) AS outlier_range
    FROM orderedList
)

SELECT
    COUNT(*) AS outlier_count
FROM iqr
WHERE duration >= ((SELECT MAX(q_three) FROM iqr) + (SELECT MAX(outlier_range) FROM iqr))
   OR duration <= ((SELECT MAX(q_one) FROM iqr) - (SELECT MAX(outlier_range) FROM iqr));

#2) probability
WITH orderedList AS (
    SELECT
        probability,
        ROW_NUMBER() OVER (ORDER BY probability) AS row_n
    FROM data
),
iqr AS (
    SELECT
        probability,
        (
            SELECT probability AS quartile_break
            FROM orderedList
            WHERE row_n = FLOOR((SELECT COUNT(*) FROM data) * 0.75)
        ) AS q_three,
        (
            SELECT probability AS quartile_break
            FROM orderedList
            WHERE row_n = FLOOR((SELECT COUNT(*) FROM data) * 0.25)
        ) AS q_one,
        1.5 * (
            (
                SELECT probability AS quartile_break
                FROM orderedList
                WHERE row_n = FLOOR((SELECT COUNT(*) FROM data) * 0.75)
            ) - (
                SELECT probability AS quartile_break
                FROM orderedList
                WHERE row_n = FLOOR((SELECT COUNT(*) FROM data) * 0.25)
            )
        ) AS outlier_range
    FROM orderedList
)

SELECT
    COUNT(*) AS outlier_count
FROM iqr
WHERE probability >= ((SELECT MAX(q_three) FROM iqr) + (SELECT MAX(outlier_range) FROM iqr))
   OR probability <= ((SELECT MAX(q_one) FROM iqr) - (SELECT MAX(outlier_range) FROM iqr));

#3) Fps
WITH orderedList AS (
    SELECT
        Fps,
        ROW_NUMBER() OVER (ORDER BY Fps) AS row_n
    FROM data
),
iqr AS (
    SELECT
        Fps,
        (
            SELECT Fps AS quartile_break
            FROM orderedList
            WHERE row_n = FLOOR((SELECT COUNT(*) FROM data) * 0.75)
        ) AS q_three,
        (
            SELECT Fps AS quartile_break
            FROM orderedList
            WHERE row_n = FLOOR((SELECT COUNT(*) FROM data) * 0.25)
        ) AS q_one,
        1.5 * (
            (
                SELECT Fps AS quartile_break
                FROM orderedList
                WHERE row_n = FLOOR((SELECT COUNT(*) FROM data) * 0.75)
            ) - (
                SELECT Fps AS quartile_break
                FROM orderedList
                WHERE row_n = FLOOR((SELECT COUNT(*) FROM data) * 0.25)
            )
        ) AS outlier_range
    FROM orderedList
)

SELECT
    COUNT(*) AS outlier_count
FROM iqr
WHERE Fps >= ((SELECT MAX(q_three) FROM iqr) + (SELECT MAX(outlier_range) FROM iqr))
   OR Fps <= ((SELECT MAX(q_one) FROM iqr) - (SELECT MAX(outlier_range) FROM iqr));
   
set sql_safe_updates=0;
#handling Outliers using Quartiles
UPDATE data AS e
JOIN ( 
    SELECT
        duration,
        probability,
        fps,
        NTILE(4) OVER (ORDER BY probability) AS probability_quartile
    FROM data
) AS subquery ON e.probability= subquery.probability
SET e.probability = (
    SELECT AVG(probability)
    FROM (
        SELECT
           duration,
           probability,
           fps,
            NTILE(4) OVER (ORDER BY probability) AS probability_quartile
        FROM data
    ) AS temp
    WHERE probability_quartile = subquery.probability_quartile
)
WHERE subquery.probability_quartile IN (1, 4);

#Transformation
update data set probability=sqrt(probability);
SET SQL_SAFE_UPDATES = 0;

#After Eda
#1) Duration
select avg(duration) as mean from data;  #41.69775550746736
select duration as median
from(select duration,row_number() over(order by duration) as row_num,
count(*) over() as total_count
from data) as subquery
where row_num=(total_count+1)/2
or row_num=(total_count+2)/2; #median=33.13
select duration,count(*) as frequency from data group by duration order by frequency desc limit 1; #mode=1.2
select max(duration)-min(duration) from data; #129.18
select stddev(duration) as standard_deviation from data; #stddev=33.427601559666506
select variance(duration) as variance from data;  #variance=1117.4045460318187
select (sum(power(duration-(select avg(duration) from data),3))/
(count(*) * power ((select stddev(duration) from data),3))
)as skewness 
from data;  #skewness=0.6993573701712712
select(sum(power(duration-(select avg(duration)from data),4))/
(count(*) *power((select stddev(duration) from data),4))-3
) as kurtosis
from data;   #kurtosis=-0.6749837716465783

#2)probability
select avg(probability) as mean from data; #mean=0.9495507588161586
select probability as median
from(select probability,row_number() over(order by probability) as row_count,
count(*) over() as total_count from data )as subquery
where row_count=(total_count+1)/2
or row_count=(total_count+2)/2;  #median=0.9959808231085576
select probability, count(*) as frequency from data group by probability order by frequency desc limit 1;  #mode=0.8241755145226347
select stddev(probability) as standard_deviation from data; #stddev=0.07362937483643814
select variance(probability) as variance from data; #variance=0.005421284838804709
select max(probability) from data; #max=0.9999966321739815
select min(probability) from data; #min=0.8241755145226347
select max(probability)-min(probability) from data; #range=0.17582111765134678
select (sum(power(probability-(select avg(probability) from data),3))/
(count(*) * power((select stddev(probability) from data),3))
)as skewness
from data;  #skewness=-1.0547847596329796
select (sum(power(probability-(select avg(probability) from data),4))/
(count(*) *power((select stddev(probability) from data),4))-3
)as kurtosis
from data;  #kurtosis=-0.7790337015031854

#3) fps
select avg(fps) as mean from data; #mean=23.262830294620073
select fps as median
from(select fps,row_number() over(order by fps) as row_count,
count(*) over() as total_count from data
)as subquery
where row_count=(total_count+1)/2
or row_count=(total_count+2)/2;  #median=29.769
select fps,count(*) as frequency from data group by fps order by frequency desc limit 1; #mode=12.496133
select stddev(fps) as standard_deviation from data;  #stddev=8.043118561372866
select variance(fps) as variance from data; #variance=64.69175619230072
select max(fps)-min(fps) from data; #range=17.548307
select max(fps) from data; #max=30.04444
select min(fps) from data;  #min=12.496133
select (sum(power(fps-(select avg(fps) from data),3))/
(count(*)*power((select stddev(fps) from data),3))
)as skewness from data;  #-0.5157911921796091
select (sum(power(fps-(select avg(fps) from data),4))/
(count(*) *power((select stddev(fps) from data),4))-3
)as kurtosis from data;   #kurtosis=-1.6243293920946955
select fps from data;

###new table
-- Create a new table
CREATE TABLE new_data (
    uid BIGINT,
    asd_project34_video_id BIGINT,
    user_name TEXT,
    duration DOUBLE PRECISION,
    class_name TEXT,
    probability DOUBLE PRECISION,
    fps DOUBLE PRECISION,
    date_time TEXT
);
select * from new_data;
-- Insert data into the new table from the existing table
INSERT INTO new_data
(uid, asd_project34_video_id, user_name, duration, class_name, probability, fps, date_time)
SELECT
uid,
asd_project34_video_id,
user_name,
duration,
class_name,
probability,
fps,
date_time
FROM data;

select * from new_data;
select stddev(probability) from new_data;
drop table data2;
select min(probability) from new_data;