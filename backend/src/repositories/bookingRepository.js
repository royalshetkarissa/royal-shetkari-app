const pool = require('../config/db');

class BookingRepository {
  async create(data) {
    const { userId, bookingDate, bookingTime, helpType, mobile } = data;
    await pool.query(
      'INSERT INTO call_bookings (user_id, booking_date, booking_time, help_type, mobile) VALUES ($1, $2, $3, $4, $5)',
      [userId, bookingDate, bookingTime, helpType, mobile]
    );
  }

  async getCount() {
    const result = await pool.query('SELECT COUNT(*) FROM call_bookings');
    return parseInt(result.rows[0].count || 0);
  }

  async getBookedSlotsByDate(date) {
    const result = await pool.query(
      'SELECT booking_time FROM call_bookings WHERE booking_date = $1',
      [date]
    );
    return result.rows.map(row => row.booking_time.toString().substring(0, 5));
  }
}

module.exports = new BookingRepository();
