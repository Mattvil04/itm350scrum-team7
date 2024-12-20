const getname = require('../src/helloworld.js'); 

test('should return "Hello Matias"', () => {
  const result = getname("Matias");
  expect(result).toBe("Hello Matias");
});
