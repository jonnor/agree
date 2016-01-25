
require('coffee-script/register');
var agree = require('./src/agree');
agree.conditions = require('./src/conditions');
agree.introspection = require('./src/introspection');
agree.doc = require('./src/doc');
agree.testing = require('./src/testing');
agree.schema = require('./src/schema'); // XXX: core or no core?

agree.express = require('./src/express'); // TEMP

module.exports = agree;
