const path = require("path");
const fs = require("fs");

// https://stackoverflow.com/questions/34907999/best-way-to-have-all-files-in-a-directory-be-entry-points-in-webpack
const sourceDirectory = "./app/javascript/packs";
const sourceFiles = fs.readdirSync(sourceDirectory)
    .filter(v => v.endsWith(".js") || v.endsWith(".ts"))
    .reduce((acc, v) => ({ ...acc, [v.slice(0, -3)]: `${sourceDirectory}/${v}` }), {});


const config = {
    mode: "production",
    module: {
        rules: [
            {
                test: /\.(js|jsx)$/,
                exclude: /node_modules/,
                use: ["babel-loader"],
            },
            {
                test: function (modulePath) {
                    return modulePath.endsWith('.ts') && !modulePath.endsWith('test.ts');
                },
                exclude: /node_modules/,
                use: ["babel-loader", "ts-loader"],
            },
        ],
    },
    optimization: {
        moduleIds: "deterministic",
        // Make sure all modules run in a single unique runtime environment.
        // This avoids modules being evaluated multiple times.
        // There is an exception for the inputServiceWorker, which needs to run standalone and thus needs its own runtime environment
        runtimeChunk: {
            name: entrypoint => entrypoint.name === "inputServiceWorker" ? false : "runtime"
        },
        splitChunks: {
            cacheGroups: {
                commons: {
                    name: "commons",
                    chunks: "initial",
                    minChunks: 2,
                },
            },
        },
    },
    entry: sourceFiles,
    output: {
        filename: "[name].js",
        sourceMapFilename: "[name].js.map",
        path: path.resolve(__dirname, "..", "..", "app/assets/builds"),
        chunkFilename: "[name].[chunkhash].nodigest.js",
    },
    resolve: {
        modules: ["node_modules", "app/assets/javascripts"],
        extensions: [".tsx", ".ts", ".mjs", ".js", ".sass", ".scss", ".css", ".module.sass", ".module.scss", ".module.css", ".png", ".svg", ".gif", ".jpeg", ".jpg"]
    },
};

if (process.env.NODE_ENV === "development") {
    config.mode = "development";
    config.devtool = "inline-source-map";
}

// Test, Staging and Production use default config

module.exports = config;
