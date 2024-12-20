const getname = require('../src/helloworld.js');

test('should correctly concatenate with other strings', () => {
  const greeting = getname("Matias");
  const fullGreeting = greeting + ", welcome!";
  expect(fullGreeting).toBe("Hello Matias, welcome!");
});
