const events = require('../backend/events.js');

describe('Events Module', () => {
  test('should export an array of events', () => {
    expect(Array.isArray(events)).toBe(true); 
  });

  test('should contain event objects with id, title, and date properties', () => {
    const event = events[0];
    expect(event).toHaveProperty('id');
    expect(event).toHaveProperty('title');
    expect(event).toHaveProperty('date');
  });
});
