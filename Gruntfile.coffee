path = require 'path'

webpackConfig = require "./webpack.config.js"

module.exports = ->
  # Project configuration
  pkg = @file.readJSON 'package.json'

  @initConfig

    # Build for browser
    webpack:
      options: webpackConfig
      build:
        plugins: webpackConfig.plugins.concat()
        name: 'agree.js'

    # Web server for the browser tests
    connect:
      server:
        options:
          port: 8000
          livereload: true

    # Coding standards
    coffeelint:
      components: ['Gruntfile.coffee', 'spec/*.coffee']
      options:
        'max_line_length':
          'level': 'ignore'

    # Tests
    coffee:
      spec:
        options:
          bare: true
        expand: true
        cwd: 'spec'
        src: '*.coffee'
        dest: 'browser/spec'
        ext: '.js'

    # Node.js
    mochaTest:
      nodejs:
        src: ['spec/*.coffee']
        options:
          reporter: 'spec'
          require: 'coffee-script/register'
          grep: process.env.TESTS

    # BDD tests on browser
    mocha_phantomjs:
      all:
        options:
          output: 'test/result.xml'
          reporter: 'spec'
          urls: ['./spec/runner.html']

  # Grunt plugins used for building
  @loadNpmTasks 'grunt-webpack'

  # Grunt plugins used for testing
  @loadNpmTasks 'grunt-mocha-phantomjs'
  @loadNpmTasks 'grunt-contrib-coffee'
  @loadNpmTasks 'grunt-mocha-test'
  #@loadNpmTasks 'grunt-coffeelint'
  #@loadNpmTasks 'grunt-contrib-connect'


  # Grunt plugins used for deploying
  #

  # Our local tasks
  @registerTask 'build', ['webpack']
  @registerTask 'test', ['build', 'coffee', 'mochaTest', 'mocha_phantomjs']

  @registerTask 'default', ['test']

