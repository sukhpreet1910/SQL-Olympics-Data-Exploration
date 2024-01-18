
copy olympic_history from '/docker-entrypoint-initdb.d/athlete_events.csv' DELIMITER ',' CSV HEADER;
copy region from '/docker-entrypoint-initdb.d/noc_regions.csv' DELIMITER ',' CSV HEADER;


SELECT *
from olympic_history

SELECT *
from region
