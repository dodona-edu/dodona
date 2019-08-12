module.exports = {
    preset: "ts-jest/presets/js-with-ts",
    globals: {
        "ts-jest": {
            tsConfig: {
                allowJs: true,
            },
        },
    },
    roots: ["app/javascript/", "app/assets/javascripts/"],
};
