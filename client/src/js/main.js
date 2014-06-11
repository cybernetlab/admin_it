requirejs.config({
  baseUrl: 'src/js',
  paths: {
    admin_it: './',
    jquery: '../../components/jquery/dist/jquery',
    underscore: '../../components/underscore/underscore',
    "underscore.string": '../../components/underscore.string/lib/underscore.string',
    backbone: '../../components/backbone/backbone'
  }
});

require(

['jquery', 'admin_it/app'],

function($, App) {
  'use strict';

  // console.log(App);
  App.initialize();
});
