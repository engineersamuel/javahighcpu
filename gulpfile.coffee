# Load all required libraries.
spawn       = require('child_process').spawn
gulp        = require 'gulp'
gutil       = require 'gulp-util'
coffee      = require 'gulp-coffee'
#sourcemaps  = require 'gulp-sourcemaps'
istanbul    = require 'gulp-istanbul'
mocha       = require 'gulp-mocha'
plumber     = require 'gulp-plumber'
bump        = require 'gulp-bump'
tag_version = require 'gulp-tag-version'
replace     = require 'gulp-replace'

gulp.on 'err', (e) ->
  gutil.beep()
  gutil.log e.err.stack

gulp.task 'coffee', ->
  gulp.src './src/**/*.coffee'
    .pipe plumber() # Prevent pipe breaking caused by errors from gulp plugins
    #.pipe sourcemaps.init()
    .pipe coffee({bare: true})
    #.pipe sourcemaps.write()
    .pipe gulp.dest './lib/'

gulp.task 'nodify', ->
  gulp.src([ './lib/cli.js' ])
    .pipe(replace('#!/usr/bin/env node;', '#!/usr/bin/env node'))
    .pipe gulp.dest('./lib/')

gulp.task 'test', ['coffee'], ->
  gulp.src ['lib/**/*.js']
    .pipe(istanbul()) # Covering files
    .pipe(istanbul.hookRequire()) # Overwrite require so it returns the covered files
    .on 'finish', ->
      gulp.src(['test/**/*.spec.coffee'])
        .pipe mocha reporter: 'spec', compilers: 'coffee:coffee-script'
        .pipe istanbul.writeReports() # Creating the reports after tests run

gulp.task 'bump', ->
  gulp.src('./package.json')
    .pipe(bump())
    .pipe gulp.dest('./')

gulp.task 'npm', (done) ->
  spawn('npm', [ 'publish' ], stdio: 'inherit').on 'close', done

gulp.task 'tag', ->
  gulp.src([ './package.json' ]).pipe tag_version()

gulp.task 'push', ->
  git.push 'origin', 'master', { args: ' --tags' }, (err) ->
    if err
      throw err

gulp.task 'watch', ->
  gulp.watch './src/**/*.coffee', ['coffee', 'nodify']

gulp.task 'release', ['bump', 'tag', 'push', 'npm']
gulp.task 'default', ['coffee']
gulp.task 'dev', ['coffee', 'watch']
