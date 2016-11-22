
var agree = null;
try {
    agree = require("./dist/agree.js");
} catch (e) {
    require('coffee-script/register');
    agree = require('./index.js');
}
module.exports = agree;
