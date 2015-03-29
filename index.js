
require('coffee-script/register');
var agree = require('./src/agree');
agree.conditions = require('./src/conditions');
agree.introspection = require('./src/introspection');

module.exports = agree;
