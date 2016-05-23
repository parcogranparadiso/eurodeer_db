-- The queries below are used to extract information about collar performances shared with the project
-- of University of Göttingen, Germany

-- Bounding box and countries of study areas [question 1]
SELECT 
  study_areas_id, study_name, name, st_extent(geom_mcp_individuals)
FROM 
  main.study_areas, env_data.world_countries_simplified
WHERE 
  st_intersects(geom_mcp_individuals, world_countries_simplified.geom)
group by 
  study_areas_id, study_name, name
order by 
  study_areas_id;

-- Number of individual per area/sex/age (age at first capture) [question 2]
SELECT 
  study_areas_id, sex, age_class_description, count(*) 
FROM 
	(SELECT distinct
	  animals.study_areas_id, 
	  gps_sensors_animals.animals_id, 
	  animals.sex, 
	  lu_age_class.age_class_description
	FROM 
	  main.gps_sensors_animals, 
	  main.animals, 
	  lu_tables.lu_age_class
	WHERE 
	  animals.animals_id = gps_sensors_animals.animals_id AND
	  lu_age_class.age_class_code = animals.age_class_code_capture) a
GROUP BY
  study_areas_id, sex, age_class_description
ORDER BY
  study_areas_id, sex, age_class_description;
  
-- Number of collars per area/brand/year [question 3]
SELECT 
  animals.study_areas_id,
  gps_sensors.vendor, 
  gps_sensors.model, 
  extract(year from gps_sensors_animals.start_time) yearx, 
  count(gps_sensors_animals.gps_sensors_id) 
FROM 
  main.gps_sensors, 
  main.gps_sensors_animals, 
  main.animals
WHERE 
  gps_sensors_animals_id IN 
  (SELECT gps_sensors_animals_id FROM(
	SELECT  gps_sensors_animals_id, rank() over(partition by gps_sensors_id ORDER BY start_time)  rankx
	  FROM main.gps_sensors_animals) a
  WHERE rankx = 1) AND
  gps_sensors.gps_sensors_id = gps_sensors_animals.gps_sensors_id AND
  gps_sensors_animals.animals_id = animals.animals_id
GROUP BY 
  animals.study_areas_id,
  gps_sensors.vendor, 
  gps_sensors.model, 
  extract(year from gps_sensors_animals.start_time)
ORDER BY 
  animals.study_areas_id,
  gps_sensors.vendor, 
  gps_sensors.model,
  extract(year from gps_sensors_animals.start_time);

-- End of deployment [question 13]
SELECT 
  study_areas_id,
  lu_end_monitoring.end_monitoring_description, 
  count(gps_sensors_animals.gps_sensors_id)
FROM 
  main.gps_sensors_animals, 
  lu_tables.lu_end_monitoring,
  main.animals
WHERE 
  gps_sensors_animals.end_monitoring_code = lu_end_monitoring.end_monitoring_code AND
  gps_sensors_animals.animals_id = animals.animals_id
GROUP BY
  study_areas_id,
  lu_end_monitoring.end_monitoring_description
ORDER BY 
  study_areas_id,
  lu_end_monitoring.end_monitoring_description;
