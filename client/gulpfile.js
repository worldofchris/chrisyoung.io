// Modules

const   autoprefixer    = require('autoprefixer'),
        browser         = require('browser-sync').create(),
        concat          = require('gulp-concat'),
        cssnano         = require('cssnano'),
        del             = require('del'),
        gulp            = require('gulp'),
        imagemin        = require('gulp-imagemin'),
        nunjucks        = require('gulp-nunjucks-render'),
        postcss         = require('gulp-postcss'),
        purgecss        = require('@fullhuman/postcss-purgecss'),
        sass            = require('gulp-sass'),
        uglify          = require('gulp-uglify');

// Paths

const paths = {
    dest: 'dist',
    html: {
        src: 'src/pages/**/*.njk',
        njk: 'src/templates',
        watch: 'src/**/*.njk'
    },
    css: {
        src: 'src/assets/scss/**/*.scss',
        dest: 'dist/assets/css'
    },
    img: {
        src: 'src/assets/img/**/*{png,jpg,gif,svg,ico}',
        dest: 'dist/assets/img'
    },
    js: {
        jquery: 'node_modules/jquery/dist/jquery.slim.js',
        popper: 'node_modules/popper.js/dist/umd/popper.js',
        bootjs: 'node_modules/bootstrap/dist/js/bootstrap.js',
        zoom: 'node_modules/zoom-vanilla.js/dist/zoom-vanilla.min.js',
        dest: 'dist/assets/js',
    }
};

// Tasks

function clean(cb) {
    return del(paths.dest)
    cb();
}

function html(cb) {
    return gulp
    .src(paths.html.src)
    .pipe(nunjucks({
        path: [paths.html.njk]
    }))
    .pipe(gulp.dest(paths.dest))
    .pipe(browser.stream())
    cb();
}

function css(cb) {
    const plugins = [
        autoprefixer(),
        cssnano()
    ];
    return gulp
    .src(paths.css.src)
    .pipe(sass({
        outputStyle: 'expanded'
    }))
    .pipe(postcss(plugins))
    .pipe(gulp.dest(paths.css.dest))
    .pipe(browser.stream())
    cb();
}

function uncss(cb) {
    const plugins = [
        purgecss({
            content: [
                paths.html.watch,
                paths.js.bootjs,
                paths.js.zoom
            ]
        }),
        autoprefixer(),
        cssnano()
    ];
    return gulp
    .src(paths.css.src)
    .pipe(sass())
    .pipe(postcss(plugins))
    .pipe(gulp.dest(paths.css.dest))
    cb();
}

function js(cb) {
    return gulp
    .src([
        paths.js.jquery,
        paths.js.popper,
        paths.js.bootjs,
        paths.js.zoom
    ])
    .pipe(concat('theme.js'))
    .pipe(uglify())
    .pipe(gulp.dest(paths.js.dest))
    .pipe(browser.stream())
    cb();
}

function img(cb) {
    return gulp
    .src(paths.img.src)
    .pipe(imagemin())
    .pipe(gulp.dest(paths.img.dest))
    .pipe(browser.stream())
    cb();
}

function watch() {
    gulp.watch(paths.html.watch, html);
    gulp.watch(paths.css.src, css);
    gulp.watch(paths.img.src, img);
}

function server(cb) {
    browser.init({
        server: paths.dest
    })
    cb();
}

exports.css = css;
exports.default = gulp.series(clean, gulp.parallel( html, css, js, img), server, watch);
exports.uncss = gulp.series(uncss);
exports.watch = gulp.parallel(server, watch);
