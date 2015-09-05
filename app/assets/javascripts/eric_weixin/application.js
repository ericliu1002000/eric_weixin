// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require_tree .
//= require foundation
//= require tinymce-jquery


//模式框弹出与关闭js代码
function openWindow(){
    document.getElementById('light').style.display='block';
    document.getElementById('fade').style.display='block';
}
function closeWindow(){
    document.getElementById('light').style.display='none';
    document.getElementById('fade').style.display='none';
}