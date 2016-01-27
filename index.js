
require('coffee-script/register');
var agree = require('./src/agree');
agree.conditions = require('./src/conditions');
agree.introspection = require('./src/introspection');
agree.schema = require('./src/schema'); // XXX: core or no core?

// TEMP: should move to agree-tools
agree.doc = require('./src/doc');
agree.testing = require('./src/testing');
agree.analyze = require('./src/analyze');

agree.express = require('./src/express'); // TEMP

module.exports = agree;
