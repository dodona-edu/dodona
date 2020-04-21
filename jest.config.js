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
    setupFiles: ["<rootDir>/test/javascript/setup-jest.ts"],
    roots: ["test/javascript/", "app/assets/"],
    moduleDirectories: [
        "node_modules",
        "app/assets/javascripts"
    ]
};
