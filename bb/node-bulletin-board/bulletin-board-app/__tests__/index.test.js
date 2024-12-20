const { index } = require('../backend/index.js');


const mockResponse = () => {
  const res = {};
  res.render = jest.fn(); 
  return res;
};

describe('Index Function', () => {
  test('should call res.render with "index"', () => {
    const req = {}; 
    const res = mockResponse();

    index(req, res);

    
    expect(res.render).toHaveBeenCalledWith('index');
  });
});
