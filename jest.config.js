module.exports = {
    preset: "ts-jest/presets/js-with-ts",
    reporters: ["default", "jest-junit"],
    globals: {
        "ts-jest": {
            tsConfig: {
                allowJs: true,
            },
        },
    },
    roots: ["test/javascript/"],
};
