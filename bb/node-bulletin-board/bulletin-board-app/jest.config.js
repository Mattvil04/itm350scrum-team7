// For every .js file in the backend directory, require at least 80% line coverage.
module.exports = {
    coverageThreshold: {
      './backend/*.js': {
        lines: 80
      }
    }
  }