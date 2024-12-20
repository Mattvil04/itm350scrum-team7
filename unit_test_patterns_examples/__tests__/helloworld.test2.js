const getname = require('../src/helloworld.js');

test('should return greetings for a list of names', () => {
  const names = ["Matias", "John", "Alice"];
  const greetings = names.map(name => getname(name));
  expect(greetings).toEqual([
    "Hello Matias",
    "Hello John",
    "Hello Alice"
  ]);
});
