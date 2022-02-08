const path = require("path");
const glob = require("glob");
const webpack = require("webpack");

// https://stackoverflow.com/questions/34907999/best-way-to-have-all-files-in-a-directory-be-entry-points-in-webpack
const entry = glob.sync("./app/javascript/packs/**.js").reduce(function (obj, el) {
    obj[path.parse(el).name] = el;
    return obj;
}, {});

// entry.assets_application = "./app/assets/javascripts/assets_application.js";

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
        moduleIds: "hashed",
    },
    entry,
    output: {
        filename: "[name].js",
        sourceMapFilename: "[name].js.map",
        path: path.resolve(__dirname, "..", "..", "app/assets/builds"),
    },
    plugins: [
        new webpack.optimize.LimitChunkCountPlugin({
            maxChunks: 1
        })
    ],
    resolve: {
        modules: ["node_modules", "app/assets/javascripts"],
        extensions: [".tsx", ".ts", ".mjs", ".js", ".sass", ".scss", ".css", ".module.sass", ".module.scss", ".module.css", ".png", ".svg", ".gif", ".jpeg", ".jpg"]
    },
};

if (process.env.NODE_ENV === "development") {
    config.mode = "development";
    config.devServer = {
        https: false,
        host: "localhost",
        port: 3035,
        public: "localhost:3035",
        hmr: false,
        // Inline should be set to true if using HMR
        inline: true,
        overlay: true,
        compress: true,
        disable_host_check: true,
        use_local_ip: false,
        quiet: false,
        headers: {
            "Access-Control-Allow-Origin": "*"
        },
        watch_options: {
            ignored: "**/node_modules/**"
        }
    };
}

if (process.env.NODE_ENV === "test") {
    config.mode = "test";
    config.output.path = path.resolve(__dirname, "..", "..", "app/assets/builds-test");
}

// Staging and Production use default config

module.exports = config;
