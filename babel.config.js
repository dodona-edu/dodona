module.exports = function (api) {
  var validEnv = ["development", "test", "production"];
  var currentEnv = api.env();
  var isDevelopmentEnv = api.env("development");
  var isProductionEnv = api.env("production");
  var isTestEnv = api.env("test");

  if (!validEnv.includes(currentEnv)) {
    throw new Error(
      "Please specify a valid `NODE_ENV` or " +
      '`BABEL_ENV` environment variables. Valid values are "development", ' +
      '"test", and "production". Instead, received: ' +
      JSON.stringify(currentEnv) +
      "."
    );
  }

  return {
    presets: [
      isTestEnv && ["@babel/preset-env", { targets: { node: "current" } }],
      (isProductionEnv || isDevelopmentEnv) && [
        "@babel/preset-env",
        {
          bugfixes: true,
          forceAllTransforms: false,
          useBuiltIns: "entry",
          corejs: 3.11,
          modules: false,
          exclude: ["transform-typeof-symbol"]
        }
      ],
      ['@babel/preset-typescript', {
        allExtensions: true,
        isTSX: true
      }]
    ].filter(Boolean),
    ignore: [],
    plugins: [
      "babel-plugin-macros",
      "@babel/plugin-syntax-dynamic-import",
      "@babel/plugin-transform-for-of",
      isTestEnv && "babel-plugin-dynamic-import-node",
      "@babel/plugin-transform-destructuring",
      ["@babel/plugin-proposal-class-properties", { loose: true }],
      ["@babel/plugin-proposal-decorators", { decoratorsBeforeExport: true }],
      ["@babel/plugin-proposal-private-methods", { loose: true }],
      ["@babel/plugin-proposal-object-rest-spread", { useBuiltIns: true }],
      ["@babel/plugin-proposal-private-property-in-object", { loose: true }],
      ["@babel/plugin-transform-runtime", {
        helpers: false,
        regenerator: true,
        corejs: false
      }],
      ["@babel/plugin-transform-regenerator", { async: false }]
    ].filter(Boolean)
  };
};
