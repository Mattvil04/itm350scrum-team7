const getname = require('../src/helloworld.js');

const testData = [
  { input: "Matias", expected: "Hello Matias" },
  { input: "John", expected: "Hello John" },
  { input: "Alice", expected: "Hello Alice" }
];

testData.forEach(({ input, expected }) => {
  test(`should return correct greeting for ${input}`, () => {
    expect(getname(input)).toBe(expected);
  });
});
