process.env.NODE_ENV = process.env.NODE_ENV || "production";

const environment = require("./environment");

const tsloader = environment.loaders.get('typescript').use.find(l => l.loader === 'ts-loader');
tsloader.options = {
  ...tsloader.options,
  reportFiles: ["!test/**/*"]
};

module.exports = environment.toWebpackConfig();
