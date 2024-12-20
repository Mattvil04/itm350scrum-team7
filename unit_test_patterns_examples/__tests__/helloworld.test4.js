const getname = require('../src/helloworld.js');

test('should return greeting within 10ms', () => {
  const start = performance.now();
  getname("Matias");
  const end = performance.now();
  expect(end - start).toBeLessThan(10); 
});
