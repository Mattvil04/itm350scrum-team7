const getname = require('../src/helloworld.js');

test('should handle high load', () => {
  for (let i = 0; i < 100000; i++) {
    const result = getname("Matias");
    expect(result).toBe("Hello Matias");
  }
});