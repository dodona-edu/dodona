module.exports = {
    preset: "ts-jest/presets/js-with-ts",
    reporters: ["default", "jest-junit"],
    globals: {
        "ts-jest": {
            tsConfig: {
                allowJs: true,
            },
        },
        // Mocking the I18N calls. The key itself will be returned as value
        "I18n": { l: k => k, t: t => t }
    },
    roots: ["test/javascript/", "app/assets/"],
    moduleDirectories: [
        "node_modules",
        "app/assets/javascripts"
    ]
};
