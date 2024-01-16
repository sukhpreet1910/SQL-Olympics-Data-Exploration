
copy olympic_history from '/docker-entrypoint-initdb.d/athlete_events.csv' DELIMITER ',' CSV HEADER;
copy region from '/docker-entrypoint-initdb.d/noc_regions.csv' DELIMITER ',' CSV HEADER;


SELECT *
from olympic_history

SELECT *
from region






-- 1. copy your csv file to docker container using this command 

-- 2. docker cp /Users/sukhsodhi/Downloads/archive/noc_regions.csv sukh-postgres:/docker-entrypoint-initdb.d/noc_regions.csv

-- 3. first is the path where the file is located in computer and second is the path where you want to copy it in docker 

-- 4. copy olympic_history from '/docker-entrypoint-initdb.d/athlete_events.csv' DELIMITER ',' CSV HEADER;

-- 5. enter the file path where you copied your profile in docker 