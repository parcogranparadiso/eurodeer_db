-- Animals that have no sensor but with a record in animals captures where no death is reported 
SELECT a.animals_id, a.study_areas_id, a.first_capture_date, b.* 
FROM (SELECT * FROM main.animals WHERE gps_deployed = 'f' AND activity_deployed= 'f' AND vhf_deployed = 'f') a
LEFT JOIN main.animals_captures b USING (animals_id)
WHERE capture_timestamp IS NOT NULL AND death = 'FALSE'
ORDER BY death, a.study_areas_id,  b.animals_id

-- Animals that have no deployment and no capture data  
SELECT a.animals_id, a.study_areas_id, a.first_capture_date, b.* 
FROM (SELECT * FROM main.animals where gps_deployed = 'f' AND activity_deployed= 'f' AND vhf_deployed = 'f') a
LEFT JOIN
main.animals_captures b USING (animals_id)
WHERE b.animals_id IS NULL 
ORDER BY death, a.study_areas_id,  a.animals_id

-- Are there the same number of captures with gps deployment in capture table as there are GPS deployments in deployments table 
SELECT * FROM 
(
-- NUMBER OF GPS DEPLOYMENTS 
SELECT animals_id, count(*) gps_sensors_animals
FROM main.gps_sensors_animals 
GROUP BY animals_id) b
JOIN 
-- NUMBER OF CAPTURES WITH GPS DEPLOYMENT 
(SELECT animals_id, count(*) captures_collaring
FROM main.animals_captures 
WHERE gps_sensors_animals_id is not null
GROUP BY animals_id) a USING (animals_id)
WHERE gps_sensors_animals != captures_collaring

-- Are there the same number of captures with VHF deployment in capture table as there are VHF deployments in deployments table 
SELECT * FROM 
(
-- NUMBER OF VHF DEPLOYMENTS 
SELECT animals_id, count(*) vhf_sensors_animals
FROM main.vhf_sensors_animals 
GROUP BY animals_id) b
JOIN 
-- NUMBER OF CAPTURES WITH VHF DEPLOYMENT 
(SELECT animals_id, count(*) captures_collaring
FROM main.animals_captures 
WHERE vhf_sensors_animals_id is not null
GROUP BY animals_id) a USING (animals_id)
WHERE vhf_sensors_animals != captures_collaring

-- Animals-Sensors with data but with a deployment interval of 1 minute 
WITH x AS(
SELECT * FROM main.gps_sensors_animals WHERE end_time - start_time = interval '1 minute')
SELECT DISTINCT x.* FROM x JOIN main.gps_data_animals USING (animals_id, gps_sensors_id)  

-- Animals-Sensors with no data (-- but with a deployment interval larger than 1 minute):
WITH y as 
(
WITH x as 
(SELECT DISTINCT animals_id, gps_sensors_id from main.gps_data_animals)
SELECT study_areas_id, start_time - end_time diff, end_deployment_code, mortality_code, z.notes, animals_original_id, x.animals_id, x.gps_sensors_id, z.animals_id animal, z.gps_sensors_id sensor, start_time, end_time FROM  x RIGHT OUTER JOIN main.gps_sensors_animals z USING (animals_id, gps_sensors_id) JOIN main.animals USING (animals_id)
)
SELECT gps_sensors_original_id, y.* FROM y join main.gps_sensors on (gps_sensors.gps_sensors_id = sensor) 
WHERE animals_id IS NULL -- AND diff != interval '-1 minute'  
ORDER BY  diff, study_areas_id, end_deployment_code
