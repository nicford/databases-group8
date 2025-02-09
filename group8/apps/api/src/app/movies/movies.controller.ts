import { Body, CACHE_MANAGER, Controller, Get, Inject, Post, Query, } from '@nestjs/common';
import { MoviesService } from './movies.service';
import { searchDto } from '@group8/api-interfaces';


@Controller('movies')
export class MoviesController {

    constructor(private movieService: MoviesService, @Inject(CACHE_MANAGER) private cache: Cache) {}

    @Get("getAllMovies")
    async getAllMovies() {
        const result = await this.movieService.getAllMovies();
        return result.rows
    }

    @Get("getMovie")
    async getMovie(@Query('id') movie_id: number) {
        const result = await this.movieService.getMovie(movie_id);
        return result.rows
    }

    // @Get("search")
    // // @UsePipes(new ValidationPipe({ transform: true }))
    // search(@Query() query: searchDto) {
    //     console.log(query);
    //     return this.movieService.search(query);
    // }

    @Post("search")
    // @UsePipes(new ValidationPipe({ transform: true }))
    async search(@Body() query: searchDto) {
        console.log('search initiated:')
        console.log(query);
        const result = await this.movieService.search(query);
        return result
    }

    @Get('cacheTest')
    async cacheTest() {
        console.log(await this.cache.keys());
        return await this.cache.keys();
    }


    // TODO: Return only rows for security !
    // TODO: Not working
    @Get('getReviews')
    async getReviews(@Query('mid') movie_id: number) {
        console.log(`getting reviews for movie with id ${movie_id}`);
        const result = await this.movieService.getMovieReviews(movie_id);
        return result
    }

    // localhost:3333/api/movie-report/getTranslations?id=862
    @Get('getTranslations')
    async getTranslations(@Query('id') movie_id: number){
        const result = await this.movieService.getTranslations(movie_id);
        console.log(result);
        return result.rows;
    }

}
