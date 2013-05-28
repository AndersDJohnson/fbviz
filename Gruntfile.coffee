module.exports = (grunt) ->

  grunt.initConfig {

    coffee:
      options:
        bare: true
      public:
        expand: true
        flatten: true
        cwd: 'src/public/coffee'
        src: ['*.coffee']
        dest: 'dist/public/js'
        ext: '.js'

    stylus:
      public:
        expand: true
        flatten: true
        cwd: 'src/public/stylus'
        src: ['*.styl']
        dest: 'dist/public/css'
        ext: '.css'

    watch:
      compile:
        files: ['src/**']
        tasks: ['compile']

  }

  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-stylus'

  grunt.registerTask 'compile', ['coffee', 'stylus']

