module.exports = (grunt) ->
  banner = """/* Hallo <%= pkg.version %> - rich text editor for jQuery UI
 * by Henri Bergius and contributors. Available under the MIT license.
 * See http://hallojs.org for more information
*/"""

  # Load Grunt tasks declared in the package.json file
  require('matchdep').filterDev('grunt-*').forEach(grunt.loadNpmTasks)

  # Project configuration
  grunt.initConfig
    pkg: @file.readJSON 'package.json'

    # Install dependencies
    bower:
      install: {}

    # CoffeeScript complication
    coffee:
      core:
        expand: true
        src: ['*.coffee']
        dest: 'tmp'
        cwd: 'src'
        ext: '.js'
      toolbar:
        expand: true
        src: ['*.coffee']
        dest: 'tmp/toolbar'
        cwd: 'src/toolbar'
        ext: '.js'
      widgets:
        expand: true
        src: ['*.coffee']
        dest: 'tmp/widgets'
        cwd: 'src/widgets'
        ext: '.js'
      plugins:
        expand: true
        src: ['*.coffee']
        dest: 'tmp/plugins'
        cwd: 'src/plugins'
        ext: '.js'
      plugins_image:
        expand: true
        src: ['*.coffee']
        dest: 'tmp/plugins/image'
        cwd: 'src/plugins/image'
        ext: '.js'
      plugins_friendly:
        expand: true
        src: ['*.coffee']
        dest: 'tmp/plugins/friendly'
        cwd: 'src/plugins/friendly'
        ext: '.js'
      gruntfile:
        files: 'Gruntfile.coffee'

    # Build setup: concatenate source files
    concat:
      options:
        stripBanners: true
        banner: banner
      full:
        src: [
          'tmp/*.js'
          'tmp/**/*.js'
          'tmp/**/**/*.js'
        ]
        dest: 'dist/hallo.js'

    # Remove tmp directory once builds are complete
    clean: ['tmp', 'dist' ]

    # JavaScript minification
    uglify:
      options:
        banner: banner
        report: 'min'
      full:
        files:
          'dist/hallo.min.js': ['dist/hallo.js']

    # Coding standards verification
    coffeelint:
      full: [
        'src/*.coffee'
        'src/**/*.coffee'
      ]

    watch:
      coffee:
        files: [ '**/*.coffee' ]
        tasks: ['build']
      styles:
        files: [ 'src/styles/**/*.less' ]
        tasks: ['recess']
      options:
        spawn: false
        livereload: true

    # Unit tests
    qunit:
      all: ['test/*.html']

    recess:
      dist:
        options:
            compile: true
        files:
            'dist/hallo.css': [
                'src/styles/hallo.less',
                'src/styles/hallo.image.less',
                'src/styles/hallo.overlay.less',
                'src/styles/friendly.less'
            ]

    connect:
      options:
        hostname: "0.0.0.0"
        base: './'
      # Cross-browser testing
      server:
        options:
          port: 9999
      # Dev server with live-reload
      dev:
        options:
          port: 9015
          middleware: (connect, options) ->
            [
              do require('connect-livereload'),

#             uploadHandler(options),

#             connect.multipart
#               uploadDir: "#{ options.base }/tmp"
#             ,

              # Serve statics
              connect.static(options.base),

              # Directory listing
              connect.directory(options.base),
            ]

    'saucelabs-qunit':
      all:
        options:
          urls: ['http://127.0.0.1:9999/test/index.html']
          browsers: [
              browserName: 'chrome'
            ,
              browserName: 'safari'
              platform: 'OS X 10.8'
              version: '6'
          ]
          build: process.env.TRAVIS_JOB_ID
          testname: 'hallo.js cross-browser tests'
          tunnelTimeout: 5
          concurrency: 3
          detailedError: true

  # Local tasks
  @registerTask 'build', ['clean', 'recess', 'coffee', 'concat']
  @registerTask 'dev', ['build', 'connect:dev', 'watch']
  @registerTask 'dist', ['build', 'uglify']
  @registerTask 'test', ['coffeelint', 'build', 'qunit']
  @registerTask 'crossbrowser', ['test', 'connect', 'saucelabs-qunit']

