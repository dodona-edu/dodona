const path = require("path");
const glob = require("glob");

const config = {
    mode: "production",
    module: {
        rules: [
            {
                test: /\.(js|jsx|ts|tsx|)$/,
                exclude: /node_modules/,
                use: ["babel-loader"],
            },
        ],
    },
    optimization: {
        moduleIds: "deterministic",
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
    // https://stackoverflow.com/questions/34907999/best-way-to-have-all-files-in-a-directory-be-entry-points-in-webpack
    entry: glob.sync("./app/javascript/packs/**.{js,ts}").reduce(function (obj, el) {
        obj[path.parse(el).name] = el;
        return obj;
    }, {}),
    output: {
        filename: "[name].js",
        sourceMapFilename: "[name].js.map",
        path: path.resolve(__dirname, "..", "..", "app/assets/builds"),
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
