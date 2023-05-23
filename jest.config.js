module.exports = {
    preset: "ts-jest/presets/js-with-ts",
    reporters: ["default", "jest-junit"],
    globals: {
        "ts-jest": {
            tsconfig: {
                "allowJs": true,
                "target": "es6",
            },
        },
    },
    setupFiles: ["<rootDir>/test/javascript/setup-jest.ts"],
    roots: ["test/javascript/", "app/assets/"],
    moduleDirectories: [
        "node_modules",
        "app/assets/javascripts"
    ],
    transformIgnorePatterns: ["node_modules/?!(d3)"],
    collectCoverageFrom: ["app/assets/javascripts/**/*.{js,ts}"],
    collectCoverage: true,
};
