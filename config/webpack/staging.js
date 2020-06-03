// Build as if in production
process.env.NODE_ENV = process.env.NODE_ENV || "production";

const environment = require("./environment");

module.exports = environment.toWebpackConfig();
