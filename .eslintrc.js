module.exports = {
  extends: [
    'eslint:recommended',
    'plugin:@typescript-eslint/eslint-recommended',
    'plugin:prettier/recommended',
    'plugin:react/recommended',
    'prettier/@typescript-eslint',
  ],
  plugins: ['@typescript-eslint'],
  parser: '@typescript-eslint/parser',
  parserOptions: {
    sourceType: 'module',
    project: './tsconfig.json',
  },
  env: {
    node: true,
  },
  globals: {
    proto: true,
    COMPILED: true,
  },
  rules: {
    quotes: [2, 'single', { avoidEscape: true }],
    'no-unused-vars': 0,
    'react/prop-types': 0,
  },
  overrides: [
    {
      files: ['*.ts', '*.tsx'],
      rules: {
        'no-dupe-class-members': 0,
      },
    },
  ],
};
