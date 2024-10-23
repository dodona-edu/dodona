module.exports = {
    preset: "ts-jest/presets/js-with-ts",
    reporters: ["default", "jest-junit"],
    setupFiles: ["<rootDir>/test/javascript/setup-jest.ts"],
    roots: ["test/javascript/", "app/assets/"],
    moduleDirectories: [
        "node_modules",
        "app/assets/javascripts"
    ],
    transform: {
        '\\.tsx?$': [
            'ts-jest',
            {
                tsconfig: {
                    "allowJs": true,
                    "target": "es6",
                },
            }
        ],
        '\\.jsx?$': ['babel-jest', {plugins: ['@babel/plugin-transform-modules-commonjs']}]
    },
    transformIgnorePatterns: ["node_modules/?!(d3)"],
    collectCoverageFrom: ["app/assets/javascripts/**/*.{js,ts}"],
};
