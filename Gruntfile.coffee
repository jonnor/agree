path = require 'path'

#webpackConfig = require "./webpack.config.js"

module.exports = ->
  # Project configuration
  pkg = @file.readJSON 'package.json'

  @initConfig
    pkg: @file.readJSON 'package.json'

    # Tests
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
          urls: ['http://localhost:8000/spec/runner.html']

  # Grunt plugins used for building
  #@loadNpmTasks 'grunt-webpack'

  # Grunt plugins used for testing
  #@loadNpmTasks 'grunt-mocha-phantomjs'
  #@loadNpmTasks 'grunt-contrib-coffee'
  @loadNpmTasks 'grunt-mocha-test'
  #@loadNpmTasks 'grunt-coffeelint'
  #@loadNpmTasks 'grunt-contrib-connect'


  # Grunt plugins used for deploying
  #

  # Our local tasks
  @registerTask 'build', []
  @registerTask 'test', ['build', 'mochaTest']

  @registerTask 'default', ['test']

