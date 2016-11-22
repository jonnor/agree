
require('coffee-script/register');
var agree = require('./src/agree');
agree.conditions = require('./src/conditions');
agree.introspection = require('./src/introspection');
agree.schema = require('./src/schema'); // XXX: core or no core?

agree.express = require('./src/express'); // TEMP
agree.chain = require('./src/chain'); // TEMP
agree.Chain = agree.chain.Chain

module.exports = agree;
