var gulp = require('gulp');
var coffee = require('gulp-coffee');
var concat = require('gulp-concat');

gulp.task('coffee', function() {
	return gulp.src('src/*.coffee')
		.pipe(concat('ld33.js'))
		.pipe(coffee())
		.pipe(gulp.dest('www'));
});

gulp.task('watch', ['default'], function() {
	gulp.watch('src/*.coffee', ['coffee']);
});

gulp.task('default', [ 'coffee' ]);

