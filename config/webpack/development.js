const environment = require('./environment');

let config = environment.toWebpackConfig();
config.devtool = 'sourcemap';
module.exports = config;
