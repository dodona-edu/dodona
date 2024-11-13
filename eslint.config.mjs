import noJquery from 'eslint-plugin-no-jquery';
import ts_eslint from 'typescript-eslint';
import eslint from "@eslint/js";
import globals from "globals";
import google_eslint from "eslint-config-google";
import jest_eslint from "eslint-plugin-jest"
import stylistic from "@stylistic/eslint-plugin";

import { FlatCompat } from "@eslint/eslintrc";

const compat = new FlatCompat();

export default ts_eslint.config(
    eslint.configs.recommended,
    ...ts_eslint.configs.recommended,
    google_eslint,
    ...compat.extends( // old eslintrc style configs, converted to new style by the compat object
                "plugin:no-jquery/all",
                "plugin:wc/recommended",
                "plugin:lit/recommended",
    ),
    {
        plugins: {
            "no-jquery": noJquery,
            "@stylistic": stylistic,
        },
        languageOptions: {
            globals: {
                ...globals.browser,
                ...globals.es2020,
                ...globals.jest,
                d3: "readonly",
                dodona: "readonly"
            },
        },
        rules: {
            "arrow-parens": ["error", "as-needed"],
            "comma-dangle": ["error", {
                "arrays": "only-multiline",
                "objects": "only-multiline",
                "imports": "only-multiline",
                "exports": "only-multiline",
                "functions": "never"
            }],
            "indent": "off",
            "max-len": "off",
            "no-invalid-this": "warn",
            "no-param-reassign": ["error", { "props": false }],
            "object-curly-spacing": ["error", "always"],
            "quotes": ["error", "double", { "allowTemplateLiterals": true }],
            "require-jsdoc": "off",
            "valid-jsdoc": "off",
            "space-before-function-paren": [
                "error",
                { "anonymous": "always", "named": "never", "asyncArrow": "always" }
            ],
            "@typescript-eslint/explicit-member-accessibility": "off",
            "@typescript-eslint/explicit-function-return-type": [
                "error",
                { "allowExpressions": true }
            ],
            "@typescript-eslint/no-parameter-properties": "off",
            "@stylistic/indent": [
                "error",
                4,
                {
                    "ignoredNodes": [
                        "FunctionExpression > .params[decorators.length > 0]",
                        "FunctionExpression > .params > :matches(Decorator, :not(:first-child))",
                        "ClassBody.body > PropertyDefinition[decorators.length > 0] > .key",
                        "TSTypeParameterInstantiation",
                        "PropertyDefinition"
                    ]
                }
            ],
            "@typescript-eslint/no-unused-vars": "warn",
            "no-unused-vars": "warn",
        },
    },{
        ignores: [
            "app/assets/config/manifest.js",
            "app/assets/javascripts/i18n/translations.js",
            "app/assets/javascripts/types/index.d.ts",
            "app/assets/javascripts/inputServiceWorker.js",
        ]
    }, {
        files: ['test/**'],
        ...jest_eslint.configs['flat/recommended'],
    }
);
