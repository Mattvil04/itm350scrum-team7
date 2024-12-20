const getname = require('../src/helloworld.js');

test('should handle async input', async () => {
  const asyncGetName = async () => {
    return getname("Matias");
  };
  const result = await asyncGetName();
  expect(result).toBe("Hello Matias");
});
