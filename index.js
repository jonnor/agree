
require('coffee-script/register');
var agree = require('./src/agree');
agree.conditions = require('./src/conditions');
agree.introspection = require('./src/introspection');
agree.doc = require('./src/doc');

agree.express = require('./src/express'); // TEMP

module.exports = agree;
