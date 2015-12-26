#global module:false

"use strict"

module.exports = (grunt) ->
    grunt.loadNpmTasks "grunt-contrib-copy"
    grunt.loadNpmTasks "grunt-contrib-cssmin"

    grunt.initConfig

        cssmin:
            build:
                files:
                    'css/clean-blog.min.css': ['css/clean-blog.css']
        copy:
            jquery:
                files: [{
                    expand: true
                    cwd: "_vendor/jquery/dist/"
                    src: "jquery*.js"
                    dest: "js/jquery"
                },
                {
                    expand: true
                    cwd: "_vendor/jquery/dist/"
                    src: "jquery.min.map"
                    dest: "js/jquery"
                }]
            bootstrap:
                files: [{
                    expand: true
                    cwd: "_vendor/bootstrap/dist/css/"
                    src: "*.css*"
                    dest: "css/bootstrap"
                },
                {
                    expand: true
                    cwd: "_vendor/bootstrap/dist/js/"
                    src: "bootstrap*.js"
                    dest: "js/bootstrap"
                },
                {
                    expand: true
                    cwd: "_vendor/bootstrap/dist/fonts/"
                    src: "*"
                    dest: "fonts/bootstrap"
                }]

    grunt.registerTask "default", [
        "copy", "cssmin"
    ]
