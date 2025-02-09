select movies.*, genre.genre_list, lang.language_list, country.country_list, rating.avg_rating, translation.translation_list, tags.tags_list from movies 
inner join(
	select distinct mid, 
		   array( select genre_inner.genre_name from genres
				  inner join(
					select genre_id, genre_name from genre_info 
				  ) as genre_inner
				 on genres.genre_id = genre_inner.genre_id 
				 where mid = $1
	) as genre_list 
	from genres 
	where mid = $1
) as genre 
on movies.mid = genre.mid
inner join (
	select distinct mid, 
		   array( select distinct language_inner.language_name from spoken_languages
				  inner join(
					select language_id, language_name from language_info 
				  ) as language_inner
				 on spoken_languages.language_id = language_inner.language_id 
				 where mid = $1
	) as language_list
	from spoken_languages 
	where mid = $1
) as lang
on movies.mid = lang.mid
inner join (
    select distinct mid, 
        array( select distinct country_inner.country_name from countries
                inner join(
                    select country_id, country_name from country_info 
                ) as country_inner
                on countries.country_id = country_inner.country_id 
                where mid = $1
    ) as country_list
    from countries 
    where mid = $1
) as country
on movies.mid = country.mid
inner join(
    select mid, avg(rating) as avg_rating from ratings where mid = $1 group by mid 
) as rating 
on movies.mid = rating.mid
inner join(
	select distinct mid, 
		   array( select distinct translation_inner.language_name from translations
				  inner join(
					select language_id, language_name from language_info 
				  ) as translation_inner
				 on translations.language_id = translation_inner.language_id 
				 where mid = $1
	) as translation_list
	from translations 
	where mid = $1
) as translation
on movies.mid = translation.mid
inner join(
	select distinct mid, 
	array(
		select distinct tag from tags where mid = $1
	) as tags_list 
	from tags where mid = $1
) as tags
on movies.mid = tags.mid