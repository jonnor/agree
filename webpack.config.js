var path = require("path");
var webpack = require("webpack");
module.exports = {
	cache: true,
    entry: './index.js',
	output: {
		path: path.join(__dirname, "dist"),
		publicPath: "dist/",
		filename: "agree.js",
		chunkFilename: "[chunkhash].js"
	},
	module: {
		loaders: [
            { test: /\.coffee$/, loader: "coffee-loader" },
		]
	},
	resolve: {
        extensions: ["", ".coffee", ".js"]
	},
	plugins: [
        // none
	]
};
