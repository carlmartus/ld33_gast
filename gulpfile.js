var gulp = require('gulp');
var coffee = require('gulp-coffee');
var concat = require('gulp-concat');
var shell = require('gulp-shell');

var SRC = ['src/gen_maps.coffe', 'src/main.coffee', 'src/env.coffee', 'src/map.coffee', 'src/state.coffee'];

gulp.task('coffee', ['maps'], function() {
	return gulp.src(SRC)
		.pipe(concat('ld33.coffee'))
		.pipe(coffee())
		.pipe(gulp.dest('www'));
});

gulp.task('maps', shell.task(['media/maps.py']));

gulp.task('watch', ['default'], function() {
	gulp.watch(SRC, ['coffee']);
	gulp.watch(['media/*.tmx', 'media/maps.py'], ['maps', 'coffee']);
});

gulp.task('default', [ 'maps', 'coffee' ]);

