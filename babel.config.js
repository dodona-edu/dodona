module.exports = function (api) {
    const validEnv = ["development", "test", "production"];
    const currentEnv = api.env();
    const isDevelopmentEnv = api.env("development");
    const isProductionEnv = api.env("production");
    const isTestEnv = api.env("test");

    if (!validEnv.includes(currentEnv)) {
        throw new Error(
            "Please specify a valid `NODE_ENV` or " +
      "`BABEL_ENV` environment variables. Valid values are \"development\", " +
      "\"test\", and \"production\". Instead, received: " +
      JSON.stringify(currentEnv) +
      "."
        );
    }

    return {
        assumptions: {
            setPublicClassFields: true,
            privateFieldsAsProperties: true,
        },
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
        ].filter(Boolean),
        ignore: [],
        plugins: [
            "babel-plugin-macros",
            isTestEnv && "babel-plugin-dynamic-import-node",
            isDevelopmentEnv && ["istanbul", { include: ["app/assets/javascripts/**/*.{js,ts}"], coverageGlobalScopeFunc: false, coverageGlobalScope: "window" }],
            ["@babel/plugin-transform-runtime", {
                helpers: false,
                regenerator: true,
                corejs: false
            }],
        ].filter(Boolean)
    };
};
