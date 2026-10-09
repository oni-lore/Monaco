/** @type {import('eslint').Linter.Config} */
const config = {
  languageOptions: {
    ecmaVersion: "latest",
    sourceType: "module",
  },
  rules: {
    "no-console": "warn",
    "no-unused-vars": "warn",
    "eqeqeq": "error",
    "semi": "error",
  },
};

export default config;