/* Проект первого модуля: анализ данных для агентства недвижимости
 * Часть 2. Решаем ad hoc задачи
 * 
 * Автор:Денисова Валерия
 * Дата:03.12.2025
*/



-- Задача 1: Время активности объявлений
-- Определим аномальные значения (выбросы) по значению перцентилей:
WITH limits AS (
    SELECT
        PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_CONT(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats
),
-- Найдём id объявлений, которые не содержат выбросы, также оставим пропущенные данные:
filtered_id AS(
    SELECT id
    FROM real_estate.flats
    WHERE
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
    ),

days_category as(
	SELECT *,
	CASE WHEN days_exposition BETWEEN 1 AND 30 THEN 'до месяца'
		WHEN days_exposition BETWEEN 31 AND 90 THEN 'до трех месяцев'
		WHEN days_exposition BETWEEN 91 AND 180 THEN 'до полугода'
		WHEN days_exposition > 181 THEN 'больше полугода'
		ELSE 'активные'
	END AS days_category
	FROM real_estate.advertisement),
city_category as(
	SELECT *,
	CASE WHEN city = 'Санкт-Петербург' THEN city
	ELSE 'ЛенОбл' 
	END AS city_cat
	FROM days_category 
	LEFT JOIN real_estate.flats USING(id)
	LEFT JOIN real_estate.city using(city_id)
	LEFT JOIN real_estate.TYPE USING (type_id)
	WHERE (EXTRACT(YEAR FROM first_day_exposition)>=2015 AND EXTRACT(YEAR FROM first_day_exposition)<=2018) AND id IN (SELECT * FROM filtered_id) AND TYPE = 'город')
SELECT city_cat AS "регион",
	days_category AS "сегмент активности",
	count(id) AS "кол-во продаваемых квартир",
	avg(last_price/total_area::numeric) AS "средняя стоимость кв. метра",
	avg(total_area) AS "средняя площадь",
	avg(last_price) AS "средняя цена квартиры",
	percentile_disc(0.5) WITHIN GROUP (ORDER BY rooms) AS "медиана кол-ва комнат",
	percentile_disc(0.5) WITHIN GROUP (ORDER BY balcony) AS "медиана кол-ва балконов",
	percentile_disc(0.5) WITHIN GROUP (ORDER BY floor) AS "медиана этажа квартиры"
FROM city_category
GROUP BY city_cat, days_category



-- Задача 2: Сезонность объявлений
-- Определим аномальные значения (выбросы) по значению перцентилей:
WITH limits AS (
    SELECT
        PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_CONT(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats
),
-- Найдём id объявлений, которые не содержат выбросы, также оставим пропущенные данные:
filtered_id AS(
    SELECT id
    FROM real_estate.flats
    WHERE
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
    ),

   
new AS ( 
	SELECT EXTRACT(MONTH FROM first_day_exposition) AS new_month,
	count(id) AS new_adv,
	avg(last_price::REAL/total_area) AS new_avg_price,
	avg(total_area) AS new_avg_area
	FROM real_estate.flats
	JOIN real_estate.advertisement USING (id)
	LEFT JOIN real_estate.TYPE USING (type_id)
	WHERE id IN (SELECT * FROM filtered_id) AND TYPE = 'город' AND extract(YEAR FROM first_day_exposition) BETWEEN 2015 AND 2018
	GROUP BY new_month),
selled AS ( 
	SELECT EXTRACT(MONTH FROM first_day_exposition + days_exposition::integer) AS selled_month,
	count(id) AS selled_adv,
	avg(last_price::REAL/total_area) AS selled_avg_price,
	avg(total_area) AS selled_avg_area
	FROM real_estate.flats
	JOIN real_estate.advertisement USING (id)
	LEFT JOIN real_estate.TYPE USING (type_id)
	WHERE id IN (SELECT * FROM filtered_id) AND TYPE = 'город' AND extract(YEAR FROM first_day_exposition) BETWEEN 2015 AND 2018
	GROUP BY selled_month)
SELECT new_month AS MONTH,
	new_adv,
	new_avg_price,
	new_avg_area,
	selled_adv, 
	selled_avg_price,
	selled_avg_area
FROM new 
JOIN selled ON NEW.new_month = selled.selled_month
ORDER BY selled_avg_area

    
    
    
    
    
    


