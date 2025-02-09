--
-- PostgreSQL database dump
--

-- Dumped from database version 13.2 (Debian 13.2-1.pgdg100+1)
-- Dumped by pg_dump version 13.2

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: tablefunc; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS tablefunc WITH SCHEMA public;


--
-- Name: EXTENSION tablefunc; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION tablefunc IS 'functions that manipulate whole tables, including crosstab';


--
-- Name: get_activity_trend(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_activity_trend(movie_id integer DEFAULT NULL::integer) RETURNS TABLE(month text, activity bigint, avg_rating numeric)
    LANGUAGE plpgsql
    AS $$
	begin
		return query  
			with 
				rating_month as (
					select 
						DATE_TRUNC('month',timestamp) AS  month, 
						count(rating) as rating_activity, avg(rating) as avg_rating 
					from ratings 
					where mid = movie_id 
					group by DATE_TRUNC('month',timestamp)
				),
				tag_month as (
					select 
						DATE_TRUNC('month',timestamp) AS  month,  
						count(tag) as tag_activity 
					from tags 
					where mid = movie_id 
					group by  DATE_TRUNC('month',timestamp)
				)
			
			select 
				to_char(processed.coalesce_month, 'YYYY-MM'),
				coalesce(processed.activity,0) as activity,
				coalesce(processed.avg_rating,0) as avg_rating
			from (
				select 
					coalesce(rating_month.month, t.month) as coalesce_month, 
					coalesce(rating_month.rating_activity, 0) + coalesce(t.tag_activity, 0) as activity, 
					rating_month.avg_rating
				from rating_month 
				full outer join (
					select tag_month.month, tag_month.tag_activity from tag_month
				) as t 
				on t.month = rating_month.month
				where (rating_month.month is not null or t.month is not null)
			) as processed;
			
end; $$;


ALTER FUNCTION public.get_activity_trend(movie_id integer) OWNER TO postgres;

--
-- Name: get_genre_company_avg(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_genre_company_avg(movie_id integer DEFAULT NULL::integer) RETURNS TABLE(genre_avg numeric, company_avg numeric)
    LANGUAGE plpgsql
    AS $$
	begin 	
		return query 
			with 
				genre_table as (
					select COALESCE(avg(genre_info.genre_avg_rating), 0) as genre_avg 
					from genre_info 
						where genre_info.genre_id in (
							select genres.genre_id from genres 
							where (movie_id ISNULL OR genres.mid = movie_id)
						)
				),
				company_table as (
					select COALESCE(avg(company_info.avg_company_rating), 0) as company_avg 
					from company_info 
						where company_info.company_id  in (
							select companies.company_id from companies 
							where (movie_id ISNULL OR companies.mid = movie_id)
						)
				)
			
			select genre_table.genre_avg, company_table.company_avg from genre_table, company_table;
end;$$;


ALTER FUNCTION public.get_genre_company_avg(movie_id integer) OWNER TO postgres;

--
-- Name: get_genre_population_avg_diff(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_genre_population_avg_diff(movie_id integer DEFAULT NULL::integer) RETURNS TABLE(local_avg numeric, animation_glob_avg numeric, animation_count bigint, adventure_glob_avg numeric, adventure_count bigint, family_glob_avg numeric, family_count bigint, comedy_glob_avg numeric, comedy_count bigint, fantasy_glob_avg numeric, fantasy_count bigint, romance_glob_avg numeric, romance_count bigint, drama_glob_avg numeric, drama_count bigint, action_glob_avg numeric, action_count bigint, crime_glob_avg numeric, crime_count bigint, thriller_glob_avg numeric, thriller_count bigint, horror_glob_avg numeric, horror_count bigint, history_glob_avg numeric, history_count bigint, science_fiction_glob_avg numeric, science_fiction_count bigint, mystery_glob_avg numeric, mystery_count bigint, war_glob_avg numeric, war_count bigint, music_glob_avg numeric, music_count bigint, documentary_glob_avg numeric, documentary_count bigint, western_glob_avg numeric, western_count bigint, tv_movie_glob_avg numeric, tv_movie_count bigint)
    LANGUAGE plpgsql
    AS $$
	begin
		return query 
			with 
				global_avg as (
					select avg(animation) as animation_glob_avg,
					   avg(adventure) as adventure_glob_avg,
					   avg(family) as family_glob_avg,
					   avg(comedy) as comedy_glob_avg,
					   avg(fantasy) as fantasy_glob_avg,
					   avg(romance) as romance_glob_avg,
					   avg(drama) as drama_glob_avg,
					   avg(action) as action_glob_avg,
					   avg(crime) as crime_glob_avg,
					   avg(thriller) as thriller_glob_avg,
					   avg(horror) as horror_glob_avg,
					   avg(history) as history_glob_avg,
					   avg(science_fiction) as science_fiction_glob_avg,
					   avg(mystery) as mystery_glob_avg,
					   avg(war) as war_glob_avg,
					   avg(music) as music_glob_avg,
					   avg(documentary) as documentary_glob_avg,
					   avg(western) as western_glob_avg,
					   avg(tv_movie) as tv_movie_glob_avg
					from user_genre_mapping
					where user_id in (select user_id from ratings where mid = movie_id)
				),
				curr_avg as (
					select 
						avg(rating) as local_avg 
					from ratings where mid = movie_id
				),
				population_table as (
					select 
						count(*) filter (where animation > (select genre_avg_rating from genre_info where genre_name = 'Animation')) as animation_count,
						count(*) filter (where family > (select genre_avg_rating from genre_info where genre_name = 'Family')) as family_count,
						count(*) filter (where history > (select genre_avg_rating from genre_info where genre_name = 'History')) as history_count,
						count(*) filter (where comedy > (select genre_avg_rating from genre_info where genre_name = 'Comedy')) as comedy_count, 
						count(*) filter (where documentary > (select genre_avg_rating from genre_info where genre_name = 'Documentary')) as documentary_count ,
						count(*) filter (where tv_movie > (select genre_avg_rating from genre_info where genre_name = 'TV Movie')) as tv_movie_count,
						count(*) filter (where fantasy > (select genre_avg_rating from genre_info where genre_name = 'Fantasy')) as fantasy_count,
						count(*) filter (where science_fiction > (select genre_avg_rating from genre_info where genre_name = 'Science Fiction')) as science_fiction_count,
						count(*) filter (where war > (select genre_avg_rating from genre_info where genre_name = 'War')) as war_count,
						count(*) filter (where music > (select genre_avg_rating from genre_info where genre_name = 'Music')) as music_count,
						count(*) filter (where horror > (select genre_avg_rating from genre_info where genre_name = 'Horror')) as horror_count,
						count(*) filter (where action > (select genre_avg_rating from genre_info where genre_name = 'Action')) as action_count,
						count(*) filter (where drama > (select genre_avg_rating from genre_info where genre_name = 'Drama')) as drama_count,
						count(*) filter (where crime > (select genre_avg_rating from genre_info where genre_name = 'Crime')) as crime_count,
						count(*) filter (where western > (select genre_avg_rating from genre_info where genre_name = 'Western')) as western_count,
						count(*) filter (where thriller > (select genre_avg_rating from genre_info where genre_name = 'Thriller')) as thriller_count,
						count(*) filter (where mystery > (select genre_avg_rating from genre_info where genre_name = 'Mystery')) as mystery_count,
						count(*) filter (where adventure > (select genre_avg_rating from genre_info where genre_name = 'Adventure')) as adventure_count,
						count(*) filter (where romance > (select genre_avg_rating from genre_info where genre_name = 'Romance')) as romance_count
					from user_genre_mapping 
					where user_id in (select user_id from ratings where mid = movie_id) 
				)

				select 
					curr_avg.local_avg, 
					global_avg.animation_glob_avg, 
					population_table.animation_count,
					global_avg.adventure_glob_avg, 
					population_table.adventure_count,
					global_avg.family_glob_avg, 
					population_table.family_count,
					global_avg.comedy_glob_avg, 
					population_table.comedy_count,
					global_avg.fantasy_glob_avg,
					population_table.fantasy_count,
					global_avg.romance_glob_avg,
					population_table.romance_count,
					global_avg.drama_glob_avg,
					population_table.drama_count,
					global_avg.action_glob_avg,
					population_table.action_count,
					global_avg.crime_glob_avg,
					population_table.crime_count,
					global_avg.thriller_glob_avg,
					population_table.thriller_count,
					global_avg.horror_glob_avg,
					population_table.horror_count,
					global_avg.history_glob_avg,
					population_table.history_count,
					global_avg.science_fiction_glob_avg,
					population_table.science_fiction_count,
					global_avg.mystery_glob_avg,
					population_table.mystery_count,
					global_avg.war_glob_avg,
					population_table.war_count,
					global_avg.music_glob_avg,
					population_table.music_count,
					global_avg.documentary_glob_avg,
					population_table.documentary_count,
					global_avg.western_glob_avg,
					population_table.western_count,
					global_avg.tv_movie_glob_avg,
					population_table.tv_movie_count
				from global_avg, curr_avg, population_table;
end; $$;


ALTER FUNCTION public.get_genre_population_avg_diff(movie_id integer) OWNER TO postgres;

--
-- Name: get_movies(integer, integer, text, text, boolean, integer, integer, integer, integer[], character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_movies(result_limit integer DEFAULT 100, result_offset integer DEFAULT 0, keyword text DEFAULT NULL::text, sort_by text DEFAULT NULL::text, ascending boolean DEFAULT true, start_year integer DEFAULT NULL::integer, end_year integer DEFAULT NULL::integer, allowed_ratings integer DEFAULT NULL::integer, genres_arg integer[] DEFAULT NULL::integer[], status_arg character varying DEFAULT NULL::character varying) RETURNS TABLE(mid integer, title text, poster_path character varying, vote_average numeric, tagline text, status character varying)
    LANGUAGE plpgsql
    AS $$ 
	begin
		return query
			select unique_filtered.mid, unique_filtered.title, unique_filtered.poster_path, unique_filtered.vote_average, unique_filtered.tagline, unique_filtered.status
			from (
				select filtered.mid, filtered.title, filtered.poster_path, round(coalesce(filtered.avg_rating,0),1) as vote_average, filtered.tagline, filtered.status, filtered.popularity, filtered.released_year, filtered.polarity
				from (
					select movies.mid, movies.title, movies.poster_path, movies.vote_average, movies.tagline, movies.popularity, movies.released_year, movies.status, genres_table.genre_id, rating_table.avg_rating, rating_table.polarity
					from movies
					inner join(
						select movie_stats.mid, movie_stats.avg_rating, movie_stats.polarity from movie_stats 
					) as rating_table
					on movies.mid = rating_table.mid
					inner join(
						select genres.mid, genres.genre_id from genres group by genres.mid, genres.genre_id	
					) as genres_table
					on movies.mid = genres_table.mid
					where 
					(keyword ISNULL OR movies.title ilike concat(keyword,'%'))
					and 
					(allowed_ratings ISNULL OR rating_table.avg_rating >= allowed_ratings)
					and 
					(status_arg ISNULL OR movies.status = status_arg)
					and 
					(genres_arg ISNULL OR genres_table.genre_id = ANY(genres_arg))
					and 
					(start_year ISNULL or movies.released_year >= start_year)
					and
					(end_year ISNULL or movies.released_year <= end_year)
					ORDER BY movies.mid
				) as filtered
				group by filtered.mid, filtered.title, filtered.poster_path, filtered.avg_rating, filtered.tagline, filtered.status, filtered.popularity, filtered.released_year, filtered.polarity
			) as unique_filtered
			ORDER BY
			CASE WHEN sort_by = 'popularity' AND ascending = FALSE THEN unique_filtered.popularity END DESC,
			CASE WHEN sort_by = 'popularity' AND ascending = TRUE THEN unique_filtered.popularity END ASC,
			CASE WHEN sort_by = 'title' AND ascending = FALSE THEN unique_filtered.title END DESC,
			CASE WHEN sort_by = 'title' AND ascending = TRUE THEN unique_filtered.title END ASC,
			CASE WHEN sort_by = 'year' AND ascending = FALSE THEN unique_filtered.released_year END DESC,
			CASE WHEN sort_by = 'year' AND ascending = TRUE THEN unique_filtered.released_year END ASC,
			CASE WHEN sort_by = 'polarity' AND ascending = FALSE THEN unique_filtered.polarity END DESC,
			CASE WHEN sort_by = 'polarity' AND ascending = TRUE THEN unique_filtered.polarity END ASC,
			CASE WHEN sort_by = 'rating' AND ascending = FALSE THEN unique_filtered.vote_average END DESC,
			CASE WHEN sort_by = 'rating' AND ascending = TRUE THEN unique_filtered.vote_average END ASC
			limit result_limit offset result_offset;
end; $$;


ALTER FUNCTION public.get_movies(result_limit integer, result_offset integer, keyword text, sort_by text, ascending boolean, start_year integer, end_year integer, allowed_ratings integer, genres_arg integer[], status_arg character varying) OWNER TO postgres;

--
-- Name: get_overview(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_overview(movie_id integer DEFAULT NULL::integer) RETURNS TABLE(mid integer, title text, overview text, budget integer, adult boolean, popularity numeric, poster_path character varying, video boolean, vote_average numeric, vote_count integer, runtime integer, status character varying, tagline text, released_year integer, revenue bigint, genre_list character varying[], language_list character varying[], country_list character varying[], avg_rating numeric, translation_list character varying[], tags_list character varying[], one_star bigint, two_star bigint, three_star bigint, four_star bigint, five_star bigint, likes bigint, dislikes bigint, cast_names character varying[], cast_roles character varying[])
    LANGUAGE plpgsql
    AS $$
	begin
		return query
			with movie_avg as (select movie_stats.mid, movie_stats.avg_rating from movie_stats where movie_stats.mid = movie_id)

			select 
				movies.mid, 
				movies.title,
				movies.overview,
				movies.budget,
				movies.adult,
				movies.popularity,
				movies.poster_path,
				movies.video,
				movies.vote_average,
				movies.vote_count,
				movies.runtime,
				movies.status,
				movies.tagline,
				movies.released_year,
				movies.revenue,
				genre.genre_list, 
				lang.language_list, 
				country.country_list, 
				rating.avg_rating, 
				translation_table.translation_list, 
				tags.tags_list,
				like_dislike.one_star,
				like_dislike.two_star,
				like_dislike.three_star,
				like_dislike.four_star,
				like_dislike.five_star,
				like_dislike.likes,
				like_dislike.dislikes,
				people_list.cast_names,
				people_list.cast_roles
			from movies 

			inner join(
				select * from movie_avg
			) as rating 
			on movies.mid = rating.mid

			left join(
				select ratings.mid,
					count(*) filter(where ratings.rating >= 1 and ratings.rating < 2) as one_star,
					count(*) filter(where ratings.rating >= 2 and ratings.rating < 3) as two_star,
					count(*) filter(where ratings.rating >= 3 and ratings.rating < 4) as three_star,
					count(*) filter(where ratings.rating >= 4 and ratings.rating < 5) as four_star,
					count(*) filter(where ratings.rating >= 5) as five_star,
					count(*) filter(where ratings.rating >= (select movie_avg.avg_rating from movie_avg)) as likes,
					count(*) filter(where ratings.rating < (select movie_avg.avg_rating from movie_avg)) as dislikes
				from ratings 
				where ratings.mid = movie_id
				group by ratings.mid
			) as like_dislike
			on movies.mid = like_dislike.mid

			left join(
				select 
					genre_group.mid,
					array_agg(genre_group.genre_name) as genre_list
				from(
					select genre_table.mid, genre_info.genre_id, genre_info.genre_name
					from genre_info 
					inner join(
						select genres.mid, genres.genre_id from genres
					) as genre_table
					on genre_info.genre_id = genre_table.genre_id
					where genre_table.mid = movie_id 
					group by genre_table.mid, genre_info.genre_id, genre_info.genre_name
				) as genre_group
				group by genre_group.mid
			) as genre 
			on movies.mid = genre.mid

			left join (
				select 
					language_group.mid,
					array_agg(language_group.language_name) as language_list
				from(
					select language_table.mid, language_info.language_id, language_info.language_name
					from language_info 
					inner join(
						select spoken_languages.mid, spoken_languages.language_id from spoken_languages
					) as language_table
					on language_info.language_id = language_table.language_id
					where language_table.mid = movie_id 
					group by language_table.mid, language_info.language_id, language_info.language_name
				) as language_group
				group by language_group.mid
			) as lang
			on movies.mid = lang.mid

			left join (
				select 
					country_group.mid,
					array_agg(country_group.country_name) as country_list
				from(
					select country_table.mid, country_info.country_id, country_info.country_name
					from country_info 
					inner join(
						select countries.mid, countries.country_id from countries
					) as country_table
					on country_info.country_id = country_table.country_id
					where country_table.mid = movie_id 
					group by country_table.mid, country_info.country_id, country_info.country_name
				) as country_group
				group by country_group.mid
			) as country
			on movies.mid = country.mid

			left join(
				select 
					language_group.mid,
					array_agg(language_group.language_name) as translation_list
				from(
					select translations.mid, language_table.language_id, language_table.language_name
					from translations 
					inner join(
						select language_info.language_id, language_info.language_name from language_info 
					) as language_table
					on translations.language_id = language_table.language_id
					where translations.mid = movie_id 
					group by translations.mid, language_table.language_id, language_table.language_name
				) as language_group
				group by language_group.mid
			) as translation_table
			on movies.mid = translation_table.mid

			left join(
				select 
					tags_table.mid, 
					array_agg( tags_table.tag ) as tags_list
				from (
					select 
						tags.mid,
						tags.tag
					from tags 
					where tags.mid = movie_id
					group by tags.mid, tags.tag
				) as tags_table
				group by tags_table.mid
			) as tags
			on movies.mid = tags.mid

			left join(
				select 
					people_group.mid,
					array_agg(people_group.name) as cast_names,
					array_agg(people_group.department) as cast_roles
				from(
					select people.mid, person_name.name, person_name.department
					from people 
					inner join(
						select person.person_id, person.name, person.department from person 
					) as person_name
					on person_name.person_id = people.person_id
					where people.mid = movie_id 
					group by people.mid, person_name.name, person_name.department
				) as people_group
				group by people_group.mid
			) as people_list 
			on movies.mid = people_list.mid;
end; $$;


ALTER FUNCTION public.get_overview(movie_id integer) OWNER TO postgres;

--
-- Name: get_personality(character varying[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_personality(tag_inputs character varying[] DEFAULT NULL::character varying[]) RETURNS TABLE(openness numeric, agreeableness numeric, emotional_stability numeric, conscientiousness numeric, extraversion numeric)
    LANGUAGE plpgsql
    AS $$
	begin 
		return query
			with avg_movie_ratings as (
				select 
					mid, 
					avg_rating 
				from movie_stats 
				where mid in 
				(
					select 
				 		mid 
				 	from tags 
				 	where tag = any(tag_inputs)
					group by mid
				)
			), 
			user_rating_map as (
				select 
					user_id, 
					prediction, 
					mov_ratings.mid, 
					mov_ratings.avg_rating 
				from user_predictive_rate 
				inner join (
					select 
						avg_movie_ratings.mid, 
						avg_movie_ratings.avg_rating from avg_movie_ratings
				) as mov_ratings
				on user_predictive_rate.mid = mov_ratings.mid
			)
	
		select 
			COALESCE(avg(traits.openness), 0) as openness,
			COALESCE(avg(traits.agreeableness), 0) as agreeableness,
			COALESCE(avg(traits.emotional_stability), 0) as emotional_stability,
			COALESCE(avg(traits.conscientiousness), 0) as conscientiousness,
			COALESCE(avg(traits.extraversion), 0) as extraversion
		from user_rating_map 
		inner join(
			select 
				user_traits.user_id, 
				user_traits.openness, 
				user_traits.agreeableness, 
				user_traits.emotional_stability, 
				user_traits.conscientiousness, 
				user_traits.extraversion 
			from user_traits
		) as traits
		on user_rating_map.user_id = traits.user_id
		where user_rating_map.prediction > user_rating_map.avg_rating;
		
end; $$;


ALTER FUNCTION public.get_personality(tag_inputs character varying[]) OWNER TO postgres;

--
-- Name: get_tag_avg(character varying[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_tag_avg(movie_tag character varying[] DEFAULT NULL::character varying[]) RETURNS TABLE(tag character varying, tag_rating numeric)
    LANGUAGE plpgsql
    AS $$
	begin 
		return query 
			select tag_table.tag, COALESCE(avg(ratings.rating),0) as tag_rating  from ratings 
			inner join (
				select tags.user_id, tags.mid, tags.tag from tags 
				where (movie_tag ISNULL or tags.tag =  any(movie_tag))
			) as tag_table
			on tag_table.mid = ratings.mid and tag_table.user_id = ratings.user_id
			group by tag_table.tag;
end $$;


ALTER FUNCTION public.get_tag_avg(movie_tag character varying[]) OWNER TO postgres;

--
-- Name: get_tag_likes_dislikes(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_tag_likes_dislikes(movie_id integer DEFAULT NULL::integer) RETURNS TABLE(tag character varying, likes bigint, dislikes bigint, polarity numeric)
    LANGUAGE plpgsql
    AS $$
	begin 
		return query
			with 
				tag_list as (
					select ratings.user_id, ratings.mid, ratings.rating, t.tag 
					from ratings 
					inner join (
						select tags.mid, tags.user_id, tags.tag from tags where tags.tag in (select tags.tag from tags where mid = movie_id)
					) as t 
					on ratings.mid = t.mid and ratings.user_id = t.user_id
				),
				tag_data as (
					select j.tag, avg(rating) 
					from (
						select tag_list.user_id, tag_list.mid, tag_list.rating, tag_list.tag  from tag_list	
					) as j
					group by j.tag
				),
				like_dislike as (
					select 
						tag_list.tag,
						count(*) filter(where tag_list.rating >= (select tag_data.avg from tag_data where tag_data.tag = tag_list.tag)) as likes,
						count(*) filter(where tag_list.rating < (select tag_data.avg from tag_data where tag_data.tag = tag_list.tag)) as dislikes
					from tag_list
					group by tag_list.tag
				)
				
				select like_dislike.tag, like_dislike.likes, like_dislike.dislikes, round(coalesce(tag_polarity.polarity,0), 2) as polarity from like_dislike
				left join(
					select tags.tag, coalesce(stddev(all_tag_ratings.rating), 0) as polarity from tags 
					inner join (
						select ratings.user_id, ratings.mid, ratings.rating from ratings 
					) as all_tag_ratings
					on all_tag_ratings.user_id = tags.user_id and all_tag_ratings.mid = tags.mid
					group by tags.tag
				) as tag_polarity
				on like_dislike.tag = tag_polarity.tag;
				
end; $$;


ALTER FUNCTION public.get_tag_likes_dislikes(movie_id integer) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: companies; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.companies (
    index integer NOT NULL,
    mid integer NOT NULL,
    company_id integer
);


ALTER TABLE public.companies OWNER TO postgres;

--
-- Name: companies_index_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.companies ALTER COLUMN index ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.companies_index_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: company_info; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.company_info (
    company_id integer NOT NULL,
    company_name character varying(100) NOT NULL,
    country_id character varying(2),
    avg_company_rating numeric
);


ALTER TABLE public.company_info OWNER TO postgres;

--
-- Name: countries; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.countries (
    index integer NOT NULL,
    mid integer NOT NULL,
    country_id character varying(2)
);


ALTER TABLE public.countries OWNER TO postgres;

--
-- Name: countries_index_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.countries ALTER COLUMN index ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.countries_index_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: country_info; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.country_info (
    country_id character varying(2) NOT NULL,
    country_name character varying(255) NOT NULL
);


ALTER TABLE public.country_info OWNER TO postgres;

--
-- Name: genre_info; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.genre_info (
    genre_id integer NOT NULL,
    genre_name character varying(20) NOT NULL,
    genre_avg_rating numeric
);


ALTER TABLE public.genre_info OWNER TO postgres;

--
-- Name: genres; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.genres (
    index integer NOT NULL,
    mid integer NOT NULL,
    genre_id integer
);


ALTER TABLE public.genres OWNER TO postgres;

--
-- Name: genres_index_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.genres ALTER COLUMN index ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.genres_index_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: language_info; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.language_info (
    language_id character varying(2) NOT NULL,
    language_name character varying(30)
);


ALTER TABLE public.language_info OWNER TO postgres;

--
-- Name: movie_stats; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.movie_stats (
    mid integer NOT NULL,
    avg_rating numeric,
    polarity numeric
);


ALTER TABLE public.movie_stats OWNER TO postgres;

--
-- Name: movies; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.movies (
    mid integer NOT NULL,
    title text NOT NULL,
    overview text,
    budget integer NOT NULL,
    adult boolean NOT NULL,
    language_id character varying(2) NOT NULL,
    popularity numeric NOT NULL,
    poster_path character varying(255),
    video boolean,
    vote_average numeric NOT NULL,
    vote_count integer NOT NULL,
    runtime integer,
    status character varying(50) NOT NULL,
    tagline text,
    released_year integer,
    revenue bigint
);


ALTER TABLE public.movies OWNER TO postgres;

--
-- Name: people; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.people (
    index integer NOT NULL,
    mid integer NOT NULL,
    person_id integer
);


ALTER TABLE public.people OWNER TO postgres;

--
-- Name: people_index_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.people ALTER COLUMN index ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.people_index_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: person; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.person (
    person_id integer NOT NULL,
    name character varying(80) NOT NULL,
    department character varying(20) NOT NULL,
    birthday date,
    deathday date,
    gender integer NOT NULL,
    birth_place character varying(255)
);


ALTER TABLE public.person OWNER TO postgres;

--
-- Name: ratings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ratings (
    index integer NOT NULL,
    user_id integer NOT NULL,
    mid integer NOT NULL,
    rating integer NOT NULL,
    "timestamp" timestamp without time zone
);


ALTER TABLE public.ratings OWNER TO postgres;

--
-- Name: ratings_index_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.ratings ALTER COLUMN index ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.ratings_index_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: spoken_languages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.spoken_languages (
    index integer NOT NULL,
    mid integer NOT NULL,
    language_id character varying(2)
);


ALTER TABLE public.spoken_languages OWNER TO postgres;

--
-- Name: spoken_languages_index_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.spoken_languages ALTER COLUMN index ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.spoken_languages_index_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: tags; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tags (
    index integer NOT NULL,
    user_id integer NOT NULL,
    mid integer NOT NULL,
    tag character varying(100) NOT NULL,
    "timestamp" timestamp without time zone
);


ALTER TABLE public.tags OWNER TO postgres;

--
-- Name: tags_index_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.tags ALTER COLUMN index ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.tags_index_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: translations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.translations (
    index integer NOT NULL,
    mid integer NOT NULL,
    language_id character varying(2) NOT NULL
);


ALTER TABLE public.translations OWNER TO postgres;

--
-- Name: translations_index_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.translations ALTER COLUMN index ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.translations_index_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: user_genre_mapping; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_genre_mapping (
    user_id integer NOT NULL,
    animation numeric,
    adventure numeric,
    family numeric,
    comedy numeric,
    fantasy numeric,
    romance numeric,
    drama numeric,
    action numeric,
    crime numeric,
    thriller numeric,
    horror numeric,
    history numeric,
    science_fiction numeric,
    mystery numeric,
    war numeric,
    music numeric,
    documentary numeric,
    western numeric,
    tv_movie numeric
);


ALTER TABLE public.user_genre_mapping OWNER TO postgres;

--
-- Name: user_names; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_names (
    user_id integer NOT NULL,
    firstname character varying(40) NOT NULL,
    lastname character varying(40) NOT NULL
);


ALTER TABLE public.user_names OWNER TO postgres;

--
-- Name: user_predictive_rate; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_predictive_rate (
    index integer NOT NULL,
    user_id character varying(50) NOT NULL,
    prediction numeric NOT NULL,
    mid integer NOT NULL
);


ALTER TABLE public.user_predictive_rate OWNER TO postgres;

--
-- Name: user_predictive_rate_index_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.user_predictive_rate ALTER COLUMN index ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.user_predictive_rate_index_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: user_traits; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_traits (
    user_id character varying(50) NOT NULL,
    openness numeric NOT NULL,
    agreeableness numeric NOT NULL,
    emotional_stability numeric NOT NULL,
    conscientiousness numeric NOT NULL,
    extraversion numeric NOT NULL
);


ALTER TABLE public.user_traits OWNER TO postgres;

--
-- Name: companies companies_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.companies
    ADD CONSTRAINT companies_pkey PRIMARY KEY (index);


--
-- Name: company_info company_info_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.company_info
    ADD CONSTRAINT company_info_pkey PRIMARY KEY (company_id);


--
-- Name: countries countries_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.countries
    ADD CONSTRAINT countries_pkey PRIMARY KEY (index);


--
-- Name: country_info country_info_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.country_info
    ADD CONSTRAINT country_info_pkey PRIMARY KEY (country_id);


--
-- Name: genre_info genre_info_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.genre_info
    ADD CONSTRAINT genre_info_pkey PRIMARY KEY (genre_id);


--
-- Name: genres genres_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.genres
    ADD CONSTRAINT genres_pkey PRIMARY KEY (index);


--
-- Name: language_info language_info_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.language_info
    ADD CONSTRAINT language_info_pkey PRIMARY KEY (language_id);


--
-- Name: movie_stats movie_stats_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.movie_stats
    ADD CONSTRAINT movie_stats_pkey PRIMARY KEY (mid);


--
-- Name: movies movies_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.movies
    ADD CONSTRAINT movies_pkey PRIMARY KEY (mid);


--
-- Name: people people_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.people
    ADD CONSTRAINT people_pkey PRIMARY KEY (index);


--
-- Name: person person_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.person
    ADD CONSTRAINT person_pkey PRIMARY KEY (person_id);


--
-- Name: ratings ratings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ratings
    ADD CONSTRAINT ratings_pkey PRIMARY KEY (index);


--
-- Name: spoken_languages spoken_languages_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.spoken_languages
    ADD CONSTRAINT spoken_languages_pkey PRIMARY KEY (index);


--
-- Name: tags tags_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT tags_pkey PRIMARY KEY (index);


--
-- Name: translations translations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.translations
    ADD CONSTRAINT translations_pkey PRIMARY KEY (index);


--
-- Name: user_genre_mapping user_genre_mapping_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_genre_mapping
    ADD CONSTRAINT user_genre_mapping_pkey PRIMARY KEY (user_id);


--
-- Name: user_names user_names_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_names
    ADD CONSTRAINT user_names_pkey PRIMARY KEY (user_id);


--
-- Name: user_predictive_rate user_predictive_rate_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_predictive_rate
    ADD CONSTRAINT user_predictive_rate_pkey PRIMARY KEY (index);


--
-- Name: user_traits user_traits_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_traits
    ADD CONSTRAINT user_traits_pkey PRIMARY KEY (user_id);


--
-- Name: companies companies_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.companies
    ADD CONSTRAINT companies_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.company_info(company_id);


--
-- Name: companies companies_mid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.companies
    ADD CONSTRAINT companies_mid_fkey FOREIGN KEY (mid) REFERENCES public.movies(mid);


--
-- Name: company_info company_info_country_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.company_info
    ADD CONSTRAINT company_info_country_id_fkey FOREIGN KEY (country_id) REFERENCES public.country_info(country_id);


--
-- Name: countries countries_country_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.countries
    ADD CONSTRAINT countries_country_id_fkey FOREIGN KEY (country_id) REFERENCES public.country_info(country_id);


--
-- Name: countries countries_mid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.countries
    ADD CONSTRAINT countries_mid_fkey FOREIGN KEY (mid) REFERENCES public.movies(mid);


--
-- Name: genres genres_genre_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.genres
    ADD CONSTRAINT genres_genre_id_fkey FOREIGN KEY (genre_id) REFERENCES public.genre_info(genre_id);


--
-- Name: genres genres_mid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.genres
    ADD CONSTRAINT genres_mid_fkey FOREIGN KEY (mid) REFERENCES public.movies(mid);


--
-- Name: movie_stats movie_stats_mid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.movie_stats
    ADD CONSTRAINT movie_stats_mid_fkey FOREIGN KEY (mid) REFERENCES public.movies(mid);


--
-- Name: people people_mid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.people
    ADD CONSTRAINT people_mid_fkey FOREIGN KEY (mid) REFERENCES public.movies(mid);


--
-- Name: people people_person_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.people
    ADD CONSTRAINT people_person_id_fkey FOREIGN KEY (person_id) REFERENCES public.person(person_id);


--
-- Name: ratings ratings_mid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ratings
    ADD CONSTRAINT ratings_mid_fkey FOREIGN KEY (mid) REFERENCES public.movies(mid);


--
-- Name: ratings ratings_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ratings
    ADD CONSTRAINT ratings_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_names(user_id);


--
-- Name: spoken_languages spoken_languages_language_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.spoken_languages
    ADD CONSTRAINT spoken_languages_language_id_fkey FOREIGN KEY (language_id) REFERENCES public.language_info(language_id);


--
-- Name: spoken_languages spoken_languages_mid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.spoken_languages
    ADD CONSTRAINT spoken_languages_mid_fkey FOREIGN KEY (mid) REFERENCES public.movies(mid);


--
-- Name: tags tags_mid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT tags_mid_fkey FOREIGN KEY (mid) REFERENCES public.movies(mid);


--
-- Name: tags tags_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT tags_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_names(user_id);


--
-- Name: translations translations_language_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.translations
    ADD CONSTRAINT translations_language_id_fkey FOREIGN KEY (language_id) REFERENCES public.language_info(language_id);


--
-- Name: translations translations_mid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.translations
    ADD CONSTRAINT translations_mid_fkey FOREIGN KEY (mid) REFERENCES public.movies(mid);


--
-- Name: user_genre_mapping user_genre_mapping_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_genre_mapping
    ADD CONSTRAINT user_genre_mapping_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_names(user_id);


--
-- Name: user_predictive_rate user_predictive_rate_mid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_predictive_rate
    ADD CONSTRAINT user_predictive_rate_mid_fkey FOREIGN KEY (mid) REFERENCES public.movies(mid);


--
-- Name: user_predictive_rate user_predictive_rate_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_predictive_rate
    ADD CONSTRAINT user_predictive_rate_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_traits(user_id);


--
-- PostgreSQL database dump complete
--

