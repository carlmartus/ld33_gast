var gulp = require('gulp');
var coffee = require('gulp-coffee');
var concat = require('gulp-concat');
var shell = require('gulp-shell');

var SRC = ['src/gen_maps.coffee', 'src/main.coffee', 'src/player.coffee'];

gulp.task('coffee', ['maps'], function() {
	return gulp.src(SRC)
		.pipe(concat('ld33.js'))
		.pipe(coffee())
		.pipe(gulp.dest('www'));
});

gulp.task('maps', function() {
	shell('media/maps.py');
});

gulp.task('watch', ['default'], function() {
	gulp.watch(SRC, ['coffee']);
	gulp.watch('media/*.tmx', ['maps', 'coffee']);
});

gulp.task('default', [ 'maps', 'coffee' ]);

