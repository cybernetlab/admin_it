define(

function() {
  'use strict';

  var iconSets = {
    fa: {},
    glyphicon: { users: 'user' }
  }

  function Icons(iconSet) {
    var set = iconSets[iconSet];
    this.icons = (set) ? set : {};
    this.set = iconSet;
  };

  Icons.prototype.get = function(name) {
    var icon = this.icons[name];
    return (icon) ? icon : name;
  };

  Icons.prototype.htmlClass = function(name) {
    console.log(this, name);
    return this.set + ' ' + this.set + '-' + this.get(name);
  }

  return Icons
});
