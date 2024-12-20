const getname = require('../src/helloworld.js');

test('should handle empty input gracefully', () => {
  const result = getname(""); 
  expect(result).toBe("Hello "); 
});

test('should handle null input gracefully', () => {
  const result = getname(null); 
  expect(result).toBe("Hello null"); 
});
