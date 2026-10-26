const { jestConfig } = require("@salesforce/sfdx-lwc-jest/config");
const setupFilesAfterEnv = jestConfig.setupFilesAfterEnv || [];
setupFilesAfterEnv.push("<rootDir>/jest-sa11y-setup.js");
module.exports = {
  ...jestConfig,
  moduleNameMapper: {
    // Jest mocks
    "^lightning/modal$": "<rootDir>/force-app/test/jest-mocks/lightning/modal",
    "^lightning/modalHeader$": "<rootDir>/force-app/test/jest-mocks/lightning/modalHeader/modalHeader",
    "^lightning/navigation$": "<rootDir>/force-app/test/jest-mocks/lightning/navigation",
    "^lightning/platformShowToastEvent$": "<rootDir>/force-app/test/jest-mocks/lightning/platformShowToastEvent"
  },
  modulePathIgnorePatterns: ["<rootDir>/.localdevserver", "<rootDir>/docs", "<rootDir>/pkg"],
  setupFiles: ["jest-canvas-mock"],
  setupFilesAfterEnv,
  testTimeout: 10000
};
